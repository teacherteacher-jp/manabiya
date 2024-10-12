class GenerationsController < ApplicationController
  def index
    @generations = Member.all.group_by(&:generation).sort_by { |generation, _| generation }.reverse
  end
end
