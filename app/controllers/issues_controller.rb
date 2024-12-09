# app/controllers/issues_controller.rb
class IssuesController < ApplicationController
  before_action :find_project

  def index
    @issues = @project.issues.open
    render json: @issues.select(:id, :subject)
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end
end
