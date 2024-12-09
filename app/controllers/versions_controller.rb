# app/controllers/versions_controller.rb
class VersionsController < ApplicationController
  before_action :find_project

  def index
    @versions = @project.versions.where.not(status: 'closed')
    render json: @versions.select(:id, :name)
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end
end
