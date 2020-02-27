# frozen_string_literal: true

class SearchController < ApplicationController
  include SearchHelper

  def index
    query = validate_query(parse_query(params[:q]))
    fetch_cards query

    params[:q] = build_query_string(query)
    if @cards.length == 1
      card = @cards.first
      redirect_to printing_path(card.printings.last.nr_set.code,
                                card.printings.last.position,
                                card.code,
                                { q: build_query_string(query) })
    else
      render 'cards/index', q: build_query_string(query)
    end
  end

  def fetch_cards(conditions)
    clauses = conditions.collect { |c| which_selector c }.compact

    @cards = Card.includes(%i[side faction card_type],
                           printings: [nr_set: [:nr_cycle]])
                 .order(:code)
    @cards = if clauses.empty?
               Card.none
             else
               clauses.inject(@cards, &:merge)
             end
    @pagy, @cards = pagy(@cards)
  end
end
