# frozen_string_literal: true

module SearchHelper
  Condition = Struct.new(:criteria, :operator, :values)

  def criteria_regex(scanner, condition)
    return unless condition.criteria.nil? && condition.operator.nil?

    condition.criteria, condition.operator = scanner.captures
  end

  def delete_quotes(cap)
    # Only delete surrounding quotes when there's no spaces in the query
    if cap.match(/\s/)
      cap
    else
      cap.delete_prefix('"').delete_suffix('"')
    end
  end

  def value_regex_parser(scanner, condition)
    if condition.criteria.nil? && condition.operator.nil?
      condition.criteria = ''
      condition.operator = ':'
    end

    return if scanner.captures[0].blank? || scanner.captures[0] == '""'

    condition.values.concat(scanner.captures.collect { |cap| delete_quotes cap })
  end

  def stepper(scanner, condition)
    loop do
      break if scanner.scan(/[[:space:]]/) || scanner.eos?

      if scanner.scan(/(\p{L})([:<>!])/)
        criteria_regex(scanner, condition)
      elsif scanner.scan(/\|?(".*?"|[\p{L}\p{N}\-\&\.\!\'\;]+)/)
        value_regex_parser(scanner, condition)
      elsif scanner.scan(/\||"/)
        # Do nothing, advance the register
      else
        # No more things to parse
        break
      end
    end
  end

  def parse_query(query)
    query = query.split.join ' '
    scanner = StringScanner.new(query)

    query_list = []
    condition = Condition.new(nil, nil, [])

    loop do
      stepper(scanner, condition)

      # Add to list when all 3 are set
      unless condition.criteria.nil? ||
             condition.operator.nil? ||
             condition.values.blank?
        query_list.push condition.dup
      end
      condition = Condition.new(nil, nil, [])
      break if scanner.eos?
    end

    query_list
  end

  FACTION_LETTERS = {
    # Corp
    'h' => 'haas bioroid',
    'j' => 'jinteki',
    'n' => 'nbn',
    'w' => 'weyland consortium',
    # Runner
    'a' => 'anarch',
    'c' => 'criminal',
    's' => 'shaper',
    # Minifactions (second letter)
    'p' => 'apex',
    'd' => 'adam',
    'u' => 'sunny lebeau',
  }.freeze

  def sanatize_factions(values)
    values.collect do |value|
      if value.length == 1
        # If given a single letter and it's valid, use the full name
        "\"#{FACTION_LETTERS[value]}\"" if FACTION_LETTERS.assoc(value)
      else
        value
      end
    end.compact
  end

  SIDE_LETTERS = {
    'r' => 'runner',
    'runner' => 'runner',
    'c' => 'corp',
    'corp' => 'corp',
  }.freeze

  def sanatize_side(values)
    values.collect do |value|
      SIDE_LETTERS[value.downcase]
    end.compact
  end

  def sanatize_values(condition)
    # Replace any single-letter factions with their full name
    if condition.criteria == 'f'
      sanatize_factions condition.values
    elsif condition.criteria == 'd'
      sanatize_side condition.values
    else
      condition.values
    end
  end

  def validate_query(conditions)
    conditions.each_with_object([]) do |condition, memo|
      new_values = sanatize_values condition

      next memo if new_values.blank?

      condition.values = new_values

      # In all cases except for when we have a < or > and not a numeric criteria,
      # keep the condition
      numeric = %w[c e h m n o p r y g]
      numeric_comparators = %w[< >]
      unless numeric_comparators.include?(condition.operator) &&
             !numeric.include?(condition.criteria)
        memo << condition
      end
    end
  end

  def build_query_string(conditions)
    conditions.collect do |condition|
      cond_str = condition.criteria.dup
      cond_str << condition.operator unless cond_str.blank?
      cond_str << condition.values.join('|')
    end
  end

  ## Criteria-specific functions

  def title_selector(condition)
    condition.values.collect do |value|
      Card.where(Card.arel_table[:name].matches("%#{value}%"))
    end.compact
  end

  def text_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.where(Card.arel_table[:text].matches("%#{value}%"))
      elsif condition.operator == '!'
        Card.where.not(Card.arel_table[:text].matches("%#{value}%"))
      end
    end.compact
  end

  def flavor_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(:printings)
            .joins(:printings)
            .where(Printing.arel_table[:flavor].matches("%#{value}%"))
      elsif condition.operator == '!'
        Card.includes(:printings)
            .joins(:printings)
            .where.not(Printing.arel_table[:flavor].matches("%#{value}%"))
      end
    end.compact
  end

  def set_selector(condition) # rubocop:disable Naming/AccessorMethodName
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(printings: [:nr_set])
            .joins(printings: [:nr_set])
            .where(NrSet.arel_table[:name].matches("%#{value}%"))
      elsif condition.operator == '!'
        Card.includes(printings: [:nr_set])
            .joins(printings: [:nr_set])
            .where.not(NrSet.arel_table[:name].matches("%#{value}%"))
      end
    end.compact
  end

  def cycle_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(printings: [nr_set: [:nr_cycle]])
            .joins(printings: [nr_set: [:nr_cycle]])
            .where(printings: { nr_sets: { nr_cycles: { name: value } } })
      elsif condition.operator == '!'
        Card.includes(printings: [nr_set: [:nr_cycle]])
            .joins(printings: [nr_set: [:nr_cycle]])
            .where.not(printings: { nr_sets: { nr_cycles: { name: value } } })
      end
    end.compact
  end

  def type_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(:card_type)
            .joins(:card_type)
            .where(CardType.arel_table[:name].matches("%#{value}%"))
      elsif condition.operator == '!'
        Card.includes(:card_type)
            .joins(:card_type)
            .where.not(CardType.arel_table[:name].matches("%#{value}%"))
      end
    end.compact
  end

  def faction_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(:faction)
            .joins(:faction)
            .where(Faction.arel_table[:name].matches("%#{value}%"))
      elsif condition.operator == '!'
        Card.includes(:faction)
            .joins(:faction)
            .where.not(Faction.arel_table[:name].matches("%#{value}%"))
      end
    end.compact
  end

  def subtype_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.where(Card.arel_table[:subtypes].matches("%#{value}%"))
      elsif condtion.operator == '!'
        Card.where.not(Card.arel_table[:subtypes].matches("%#{value}%"))
      end
    end.compact
  end

  def side_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(:side)
            .joins(:side)
            .where(Side.arel_table[:name].matches("%#{value}%"))
      elsif condition.operator == '!'
        Card.includes(:side)
            .joins(:side)
            .where.not(Side.arel_table[:name].matches("%#{value}%"))
      end
    end.compact
  end

  def illustrator_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(:printings)
            .joins(:printings)
            .where(Printing.arel_table[:illustrator].matches("%#{value}%"))
      elsif condition.operator == '!'
        Card.includes(:printings)
            .joins(:printings)
            .where.not(Printing.arel_table[:illustrator].matches("%#{value}%"))
      end
    end.compact
  end

  def cost_x_selector(condition)
    if condition.operator == ':'
      Card.includes(:card_type)
          .joins(:card_type)
          .where(cost: nil)
          .where.not(card_types: { name: %w[Agenda Identity] })
    elsif condition.operator == '!'
      Card.where.not(cost: nil)
    end
  end

  def cost_selector(condition)
    condition.values.collect do |value|
      if %w[x X].member? value
        cost_x_selector(condition)
      elsif condition.operator == ':'
        Card.where(cost: value)
      elsif condition.operator == '!'
        Card.where.not(cost: value)
      elsif condition.operator == '<'
        Card.where(Card.arel_table[:cost].lt(value))
      elsif condition.operator == '>'
        Card.where(Card.arel_table[:cost].gt(value))
      end
    end.compact
  end

  def advancement_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.where(advancement_requirement: value)
      elsif condition.operator == '!'
        Card.where.not(advancement_requirement: value)
      elsif condition.operator == '<'
        Card.where(Card.arel_table[:advancement_requirement].lt(value))
      elsif condition.operator == '>'
        Card.where(Card.arel_table[:advancement_requirement].gt(value))
      end
    end.compact
  end

  def memory_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.where(memory_cost: value)
      elsif condition.operator == '!'
        Card.where.not(memory_cost: value)
      elsif condition.operator == '<'
        Card.where(Card.arel_table[:memory_cost].lt(value))
      elsif condition.operator == '>'
        Card.where(Card.arel_table[:memory_cost].gt(value))
      end
    end.compact
  end

  def influence_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.where(influence_cost: value).or(Card.where(influence_limit: value))
      elsif condition.operator == '!'
        Card.where.not(influence_cost: value).or(Card.where.not(influence_limit: value))
      elsif condition.operator == '<'
        Card.where(Card.arel_table[:influence_cost].lt(value))
            .or(Card.where(Card.arel_table[:influence_limit].lt(value)))
      elsif condition.operator == '>'
        Card.where(Card.arel_table[:influence_cost].gt(value))
            .or(Card.where(Card.arel_table[:influence_limit].gt(value)))
      end
    end.compact
  end

  def strength_x_selector(condition)
    if condition.operator == ':'
      Card.includes(:card_type)
          .joins(:card_type)
          .where(strength: nil)
          .where(Card.arel_table[:subtypes].matches('%icebreaker%'))
          .or(Card.includes(:card_type)
                  .joins(:card_type)
                  .where(strength: nil)
                  .where(CardType.arel_table[:name].matches('ICE')))
    elsif condition.operator == '!'
      Card.where.not(strength: nil)
    end
  end

  def strength_selector(condition)
    condition.values.collect do |value|
      if %w[x X].member? value
        strength_x_selector(condition)
      elsif condition.operator == ':'
        Card.where(strength: value)
      elsif condition.operator == '!'
        Card.where.not(strength: value)
      elsif condition.operator == '<'
        Card.where(Card.arel_table[:strength].lt(value))
      elsif condition.operator == '>'
        Card.where(Card.arel_table[:strength].gt(value))
      end
    end.compact
  end

  def agenda_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.where(agenda_points: value)
      elsif condition.operator == '!'
        Card.where.not(agenda_points: value)
      elsif condition.operator == '<'
        Card.where(Card.arel_table[:agenda_points].lt(value))
      elsif condition.operator == '>'
        Card.where(Card.arel_table[:agenda_points].gt(value))
      end
    end.compact
  end

  def trash_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.where(trash_cost: value)
      elsif condition.operator == '!'
        Card.where.not(trash_cost: value)
      elsif condition.operator == '<'
        Card.where(Card.arel_table[:trash_cost].lt(value))
      elsif condition.operator == '>'
        Card.where(Card.arel_table[:trash_cost].gt(value))
      end
    end.compact
  end

  def quantity_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(:printings)
            .joins(:printings)
            .where(printings: { quantity: value })
      elsif condition.operator == '!'
        Card.includes(:printings)
            .joins(:printings)
            .where.not(printings: { quantity: value })
      elsif condition.operator == '<'
        Card.includes(:printings)
            .joins(:printings)
            .where(Printing.arel_table[:quantity].lt(value))
      elsif condition.operator == '>'
        Card.includes(:printings)
            .joins(:printings)
            .where(Printing.arel_table[:quantity].gt(value))
      end
    end.compact
  end

  def date_selector(condition)
    condition.values.collect do |value|
      if condition.operator == ':'
        Card.includes(:printings)
            .joins(:printings)
            .where(printings: { date_release: value })
      elsif condition.operator == '!'
        Card.includes(:printings)
            .joins(:printings)
            .where.not(printings: { date_release: value })
      elsif condition.operator == '<'
        Card.includes(:printings)
            .joins(:printings)
            .where(Printing.arel_table[:date_release].lt(value))
      elsif condition.operator == '>'
        Card.includes(:printings)
            .joins(:printings)
            .where(Printing.arel_table[:date_release].gt(value))
      end
    end.compact
  end

  def uniqueness_selector(condition)
    condition.values.collect do |value|
      value = %w[1 true].member?(value)
      if condition.operator == ':'
        Card.where(uniqueness: value)
      else
        Card.where.not(uniqueness: value)
      end
    end.compact
  end

  CASE_HASH = {
    '' => :title_selector,
    'x' => :text_selector,
    'a' => :flavor_selector,
    'e' => :set_selector,
    'c' => :cycle_selector,
    't' => :type_selector,
    'f' => :faction_selector,
    's' => :subtype_selector,
    'd' => :side_selector,
    'i' => :illustrator_selector,
    'o' => :cost_selector,
    'g' => :advancement_selector,
    'm' => :memory_selector,
    'n' => :influence_selector,
    'p' => :strength_selector,
    'v' => :agenda_selector,
    'h' => :trash_selector,
    'y' => :quantity_selector,
    'r' => :date_selector,
    'u' => :uniqueness_selector,
  }.freeze

  def which_selector(condition)
    # For each criteria, we have a function that takes a single condition (criteria,
    # operator, and array of values) and return an array of WHERE clauses that are
    # joined together with an OR or AND, depending on the operator provided.

    # This is necessary because we only want the quotes in the params. The values in the
    # database don't have quotes so we don't want them.
    condition.values = condition.values.collect do |value|
      value.delete_prefix('"').delete_suffix('"')
    end

    joiner = condition.operator == ':' ? :or : :merge

    send(CASE_HASH[condition.criteria], condition).inject(&joiner)
  end
end
