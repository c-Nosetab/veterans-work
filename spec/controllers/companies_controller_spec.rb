require 'rails_helper'
require 'spec_helper'


RSpec.describe CompaniesController, type: :controller do

  describe "get #index" do
    it 'assigns all companies to @companies' do
      companies_list = []
      5.times do
        companies_list << create(:company)
      end
      get :index
      expect(assigns(:companies)).to eq("companies_list")
    end
  end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index.html.erb")
    end
  end

  describe 'GET #show' do
    it 'assigns the company to @company' do
      company = create(:company)
      get :show, id: company.id
      expect(assigns(:company)).to eq(company)
    end
  end
end
