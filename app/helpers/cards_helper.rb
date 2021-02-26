# frozen_string_literal: true

module CardsHelper
  def load_edn_from_dir(path)
    cards = []
    Dir.glob(path) do |f|
      next if File.directory? f

      File.open(f) do |file|
        cards << EDN.read(file)
      end
    end
    cards
  end

  def convert_symbol(type)
    return if type.nil?

    type.to_s.underscore
  end

  def convert_subtype(subtypes)
    return if subtypes.nil?

    subtypes.map(&:to_s).map(&:upcase_first).join(' - ')
  end

  def import_sides(path)
    path += 'sides.edn'
    sides = nil
    File.open(path) do |file|
      sides = EDN.read(file)
    end
    sides
      .map! do |side|
      {
        code: convert_symbol(side[:id]),
        name: side[:name],
      }
    end
    Side.import sides, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def import_factions(path)
    path += 'factions.edn'
    factions = nil
    File.open(path) do |file|
      factions = EDN.read(file)
    end
    factions
      .map! do |faction|
      {
        code: convert_symbol(faction[:id]),
        is_mini: faction[:"is-mini"],
        name: faction[:name],
      }
    end
    Faction.import factions, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def import_types(path)
    path += 'types.edn'
    types = nil
    File.open(path) do |file|
      types = EDN.read(file)
    end
    types
      .map! do |type|
      {
        code: convert_symbol(type[:id]),
        name: type[:name],
      }
    end
    CardType.import types, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def import_subtypes(path)
    path += 'subtypes.edn'
    subtypes = nil
    File.open(path) do |file|
      subtypes = EDN.read(file)
    end
    subtypes
      .map! do |subtype|
      {
        code: convert_symbol(subtype[:id]),
        name: subtype[:name],
      }
    end
    Subtype.import subtypes, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def import_cards(path: '../netrunner-data/edn/')
    cards = load_edn_from_dir(path + 'cards/*.edn')
    factions = Faction.all.index_by(&:code)
    sides = Side.all.index_by(&:code)
    types = CardType.all.index_by(&:code)
    subtypes = Subtype.all.index_by(&:code)

    new_cards = []
    cards.each do |card|
      new_card = Card.new(
        advancement_requirement: card[:"advancement-requirement"],
        agenda_points: card[:"agenda-points"],
        base_link: card[:"base-link"],
        code: card[:id],
        cost: card[:cost],
        deck_limit: card[:"deck-limit"],
        influence_cost: card[:"influence-cost"],
        influence_limit: card[:"influence-limit"],
        memory_cost: card[:"memory-cost"],
        minimum_deck_size: card[:"minimum-deck-size"],
        name: card[:title],
        subtypes: card[:subtype]&.collect { |x| subtypes[convert_symbol(x)].name }&.join(' - '),
        strength: card[:strength],
        text: card[:text],
        trash_cost: card[:"trash-cost"],
        uniqueness: card[:uniqueness]
      )
      new_card.faction = factions[convert_symbol(card[:faction])] if card[:faction]
      new_card.side = sides[convert_symbol(card[:side])] if card[:side]
      new_card.card_type = types[convert_symbol(card[:type])] if card[:type]
      card[:subtype]&.each do |s|
        new_card.subtype_relations << subtypes[convert_symbol(s)]
      end
      new_cards << new_card
    end
    new_cards.each_slice(100) { |nc|
      Card.import nc, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
    }
  end

  def select_cycle_code(code)
    codes = {
      'revised-core': 'core2',
      'napd-multiplayer': 'napd',
      'system-core-2019': 'sc19',
    }
    codes[code] || code
  end

  def import_cycles(path)
    path += 'cycles.edn'
    cycles = nil
    File.open(path) do |file|
      cycles = EDN.read(file)
    end
    cycles
      .map! do |cy|
      {
        code: select_cycle_code(cy[:id]),
        name: cy[:name],
        description: cy[:description],
      }
    end
    NrCycle.import cycles, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def import_set_types(path)
    path += 'set-types.edn'
    set_types = nil
    File.open(path) do |file|
      set_types = EDN.read(file)
    end
    set_types
      .map! do |set_type|
      {
        code: convert_symbol(set_type[:id]),
        name: set_type[:name],
      }
    end
    NrSetType.import set_types, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def import_sets(path)
    nr_cycles = NrCycle.all.index_by(&:code)
    nr_set_types = NrSetType.all.index_by(&:code)

    path += 'sets.edn'
    sets = nil
    File.open(path) do |file|
      sets = EDN.read(file)
    end

    new_sets = []
    sets.each do |set|
      new_set = NrSet.new(
        code: set[:id],
        name: set[:name],
        date_release: set[:"date-release"] ? Date.parse(set[:"date-release"]) : nil,
        size: set[:size],
        nr_cycle:  nr_cycles[select_cycle_code(set[:"cycle-id"])],
        nr_set_type: set[:"set-type"] ? nr_set_types[convert_symbol(set[:"set-type"])] : nil,
      )

      new_sets << new_set
    end
    NrSet.import new_sets, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def import_printings(path)
    set_cards = load_edn_from_dir(path + 'set-cards/*.edn').flatten
    raw_cards = Card.all.index_by(&:code)
    nr_sets = NrSet.all.index_by(&:code)

    new_printings = []
    set_cards.each do |set_card|
      card = raw_cards[set_card[:"card-id"]]
      nr_set = nr_sets[set_card[:"set-id"]]

      new_printing = Printing.new(
        printed_text: card[:text],
        printed_uniqueness: card[:uniqueness],
        code: set_card[:code],
        flavor: set_card[:flavor],
        illustrator: set_card[:illustrator],
        position: set_card[:position],
        quantity: set_card[:quantity],
        date_release: nr_set[:date_release]
      )
      new_printing.card = card
      new_printing.nr_set = nr_set

      new_printings << new_printing
    end
    new_printings.each_slice(100) { |np|
      Printing.import np, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
    }
  end

  def import_legality_types
    legality_types = []
    legality_types << LegalityType.new(name: 'Legal', code: 'legal')
    legality_types << LegalityType.new(name: 'Not Legal', code: 'not_legal')
    legality_types << LegalityType.new(name: 'Restricted', code: 'restricted')
    legality_types << LegalityType.new(name: 'Banned', code: 'banned')
    LegalityType.import legality_types, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def import_formats
    deck_formats = []
    deck_formats << DeckFormat.new(name: 'Standard', code: 'standard')
    deck_formats << DeckFormat.new(name: 'Eternal', code: 'eternal')
    deck_formats << DeckFormat.new(name: 'Core Experience', code: 'core_experience')
    deck_formats << DeckFormat.new(name: 'Snapshot', code: 'snapshot')
    deck_formats << DeckFormat.new(name: 'Cache Refresh', code: 'cache_refresh')
    deck_formats << DeckFormat.new(name: 'Classic', code: 'classic')
    DeckFormat.import deck_formats, on_duplicate_key_update: { conflict_target: [ :code ], columns: :all }
  end

  def select_legality_type(type)
    if type == :rotated
      'not_legal'
    else
      type.to_s
    end
  end

  def select_format(format)
    formats = {
      'core-experience': 'core_experience',
      'socr': 'cache_refresh',
    }
    formats[format] || format.to_s
  end

  def import_card_legalities(path)
    path += 'raw_data.edn'
    raw_data = nil
    File.open(path) do |file|
      raw_data = EDN.read(file)
    end

    cards = Card.all.index_by(&:code)
    types = LegalityType.all.index_by(&:code)
    formats = DeckFormat.all.index_by(&:code)

    l = []
    raw_data[:cards].each do |card|
      card[:format].each do |ff, ll|
        next if ff == :'snapshot-plus'

        l << Legality.new(
          legality_type: types[select_legality_type(ll)],
          deck_format: formats[select_format(ff)],
          card: cards[card[:normalizedtitle]]
        )
      end
    end
    l.each_slice(100) {|s|
      Legality.import s, on_duplicate_key_update: { conflict_target: [ :deck_format_id, :card_id], columns: :all }
    }
  end

  def import
    path = '../netrunner-data/edn/'

    p '[%s] Importing sides...' % [Time.new]
    import_sides path
    p '[%s] Importing factions...' % [Time.new]
    import_factions path
    p '[%s] Importing types...' % [Time.new]
    import_types path
    p '[%s] Importing subtypes...' % [Time.new]
    import_subtypes path
    p '[%s] Importing cards...' % [Time.new]
    import_cards path: path

    p '[%s] Importing cards...' % [Time.new]
    import_cycles path
    p '[%s] Importing set types...' % [Time.new]
    import_set_types path
    p '[%s] Importing sets...' % [Time.new]
    import_sets path
    p '[%s] Importing printings...' % [Time.new]
    import_printings path

    p '[%s] Importing legality types...' % [Time.new]
    import_legality_types
    p '[%s] Importing formats...' % [Time.new]
    import_formats
    p '[%s] Importing card legalities...' % [Time.new]
    import_card_legalities path

    p '[%s] Done!' % [Time.new]
  end
end
