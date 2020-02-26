# frozen_string_literal: true

class CardsController < ApplicationController
  def index
    @cards = Card.includes(%i[side faction card_type],
                           printings: [nr_set: [:nr_cycle]])
                 .order(:code)
    @pagy, @cards = pagy(@cards)
  end

  def show
    @card = Card.find_by(code: params[:code])
    return if @card.present?

    redirect_to cards_path
  end
end
