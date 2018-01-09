# == Schema Information
#
# Table name: contracts
#
#  id                  :integer          not null, primary key
#  quote_id            :integer
#  customer_request_id :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  completion_date     :date
#  company_id          :integer
#

require 'rails_helper'

RSpec.describe ContractsController, type: :controller do
  describe 'GET #index' do
    context 'when current_customer is logged in' do
      it 'renders the index html showing contracts of the signed in customer' do
        customer = create(:customer)
        sign_in customer
        customer_request = create(:customer_request, customer_id: customer.id)
        contract = create(:contract, customer_request_id: customer_request.id)
        get :index
        expect(response).to render_template("index")
      end

      it 'assigns the expected active contracts to @active_contracts' do
        customer = create(:customer)
        sign_in customer
        customer_request = create(:customer_request, customer: customer)
        contract = create(
          :contract,
          customer_request: customer_request,
          completion_date: nil
        )
        get :index
        expect(assigns(:active_contracts)).to match_array([contract])
      end

    end

    context 'when current_company is logged in' do
      it 'assigns the expected active contracts to @active_contracts' do
        company = create(:company)
        sign_in company
        customer_request = create(:customer_request)
        quote = create(:quote, customer_request_id: customer_request.id, company_id: company.id)
        contract = create(
          :contract,
          customer_request_id: customer_request.id,
          quote_id: quote.id,
          completion_date: nil,
          company_id: company.id
        )
        get :index
        expect(assigns(:active_contracts)).to match_array([contract])
      end

      it 'renders the index html showing contracts of the signed in company' do
        customer = create(:customer)
        company = create(:company)
        sign_in company
        customer_request = create(:customer_request)
        quote = create(:quote, customer_request_id: customer_request.id, company_id: company.id)
        contract = create(:contract, customer_request_id: customer_request.id, quote_id: quote.id, company_id: company.id) 
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when current_company or current_customer is not logged in' do
      it 'redirects to the root' do
        get :index
        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'POST #create' do
    it 'creates and saves a new contract to the database' do
      company_one = create(:company)
      company_two = create(:company)
      company_three = create(:company)
      customer = create(:customer)
      sign_in customer
      customer_request = create(:customer_request, customer_id: customer.id)
      quote_one = create(
        :quote,
        company_id: company_one.id,
        customer_request_id: customer_request.id
      )
      quote_two = create(
        :quote,
        company_id: company_two.id,
        customer_request_id: customer_request.id
      )
      quote_three = create(
        :quote,
        company_id: company_three.id,
        customer_request_id: customer_request.id
      )
      expect{
        post :create, params: {
          contract: {
            quote_id: quote_one.id
          }
        }
      }.to change(Contract, :count).by(1)
    end

    it 'sends an email to each company that has created a quote' do
      company_one = create(:company)
      company_two = create(:company)
      company_three = create(:company)
      customer = create(:customer)
      sign_in customer
      customer_request = create(:customer_request, customer_id: customer.id)
      quote_one = create(
        :quote,
        company_id: company_one.id,
        customer_request_id: customer_request.id
      )
      quote_two = create(
        :quote,
        company_id: company_two.id,
        customer_request_id: customer_request.id
      )
      quote_three = create(
        :quote,
        company_id: company_three.id,
        customer_request_id: customer_request.id
      )
      expect {
        post :create, params: {
          contract: {
            quote_id: quote_one.id,
            customer_request_id: customer_request.id
          }
        }
      }.to change { ActionMailer::Base.deliveries.count }.by(3)
    end

    describe 'quote status updated' do
      it 'marks declined quotes as false and accepted quotes as true' do
        company_one = create(:company)
        company_two = create(:company)
        customer = create(:customer)
        sign_in customer
        customer_request = create(:customer_request, customer_id: customer.id)
        quote_one = create(
          :quote,
          company_id: company_one.id,
          customer_request_id: customer_request.id
        )
        quote_two = create(
          :quote,
          company_id: company_two.id,
          customer_request_id: customer_request.id
        )
        post :create, params: {
          contract: {
            quote_id: quote_one.id,
            customer_request_id: customer_request.id
          }
        }
        expect(quote_one.reload.accepted).to eq(true)
        expect(quote_two.reload.accepted).to eq(false)
      end
    end

  end

  describe 'GET #show' do
    it 'assigns the requested contract to @contract' do
      @company_one = create(:company)
      @company_two = create(:company)
      @company_three = create(:company)
      @customer = create(:customer)
      sign_in @customer
      @customer_request = create(:customer_request, customer_id: @customer.id)
      @quote_one = create(
        :quote,
        company_id: @company_one.id,
        customer_request_id: @customer_request.id,
        accepted: true
      )
      @quote_two = create(
        :quote,
        company_id: @company_two.id,
        customer_request_id: @customer_request.id,
        accepted: nil
      )
      @quote_three = create(
        :quote,
        company_id: @company_three.id,
        customer_request_id: @customer_request.id,
        accepted: nil
      )
      @contract = create(
        :contract,
        customer_request_id: @customer_request.id,
        quote_id: @quote_one.id
      )
      get :show, params: { id: @contract.id }
      expect(assigns(:contract)).to eq(@contract)
    end

    context 'when current_customer or current_company is not logged in' do
      it 'redirects to show page if not logged in as current Company or Customer' do
        @company = create(:company)
        @customer = create(:customer)
        @customer_request = create(:customer_request, customer_id: @customer.id)
        @quote = create(
          :quote,
          company_id: @company.id,
          customer_request_id: @customer_request.id,
          accepted: nil
        )
        @contract = create(
          :contract,
          customer_request_id: @customer_request.id,
          quote_id: @quote.id
        )
        get :show, params: { id: @contract.id }
        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'PATCH #update' do
    context 'with customer signed in' do
      before :each do
        @company_one = create(:company)
        @company_two = create(:company)
        @customer = create(:customer)
        sign_in @customer
        @customer_request = create(:customer_request, customer_id: @customer.id)
        @customer_request2 = create(:customer_request, customer_id: @customer.id)
        @quote_one = create(
          :quote,
          company_id: @company_one.id,
          customer_request_id: @customer_request.id,
          accepted: true
        )
        @quote_two = create(
          :quote,
          company_id: @company_one.id,
          customer_request_id: @customer_request2.id,
          accepted: true
        )
        @quote_three = create(
          :quote,
          company_id: @company_two.id,
          customer_request_id: @customer_request.id,
          accepted: nil
        )
        @contract_one = create(
          :contract,
          customer_request_id: @customer_request.id,
          quote_id: @quote_one.id
        )
        @contract_two = create(
          :contract,
          customer_request_id: @customer_request2.id,
          quote_id: @quote_two.id
        )
      end

      it 'assigns the correct contract to @contract' do
        put :update, params: {
          id: @contract_one.id,
          contract: {
            completion_date: Date.today
          }
        }
        expect(assigns(:contract)).to eq(@contract_one)
      end

      it 'should save the contract completion date' do
        today = Date.today
        put :update, params: {
          id: @contract_one.id,
          contract: {
            completion_date: today
          }
        }
        expect(@contract_one.reload.completion_date).to eq(today)
      end
    end

    context 'with company signed in' do
      before :each do
        @company_one = create(:company)
        @company_two = create(:company)
        @customer = create(:customer)
        sign_in @company_one
        @customer_request = create(:customer_request, customer_id: @customer.id)
        @customer_request2 = create(:customer_request, customer_id: @customer.id)
        @quote_one = create(
          :quote,
          company_id: @company_one.id,
          customer_request_id: @customer_request.id,
          accepted: true
        )
        @quote_two = create(
          :quote,
          company_id: @company_one.id,
          customer_request_id: @customer_request2.id,
          accepted: nil
        )
        @quote_three = create(
          :quote,
          company_id: @company_two.id,
          customer_request_id: @customer_request.id,
          accepted: nil
        )
        @contract_one = create(
          :contract,
          customer_request_id: @customer_request.id,
          quote_id: @quote_one.id,
          company_id: @company_one.id,
          completion_date: nil
        )
        @contract_two = create(
          :contract,
          customer_request_id: @customer_request2.id,
          quote_id: @quote_two.id,
          company_id: @company_one.id,
          completion_date: nil
        )
        @contract_three = create(
          :contract,
          customer_request_id: @customer_request.id,
          quote_id: @quote_three.id,
          company_id: @company_two.id,
          completion_date: nil
        )
      end

      it 'assigns the correct contract to @contract' do
        put :update, params: {
          id: @contract_one.id,
          contract: {
            completion_date: Date.today
          }
        }
        expect(assigns(:contract)).to eq(@contract_one)
      end

      it 'should save the contract completion date' do
        today = Date.today
        put :update, params: {
          id: @contract_one.id,
          contract: {
            completion_date: today
          }
        }
        expect(@contract_one.reload.completion_date).to eq(today)
      end

      it "should not allow edits for other people's contracts" do
        today = Date.today
        put :update, params: {
          id: @contract_three.id,
          contract: {
            completion_date: today
          }
        }
        expect(@contract_three.reload.completion_date).to eq(nil)
      end

      it 'should not allow completion dates in the future' do
        today = Date.today
        put :update, params: {
          id: @contract_one.id,
          contract: {
            completion_date: today + 1.day
          }
        }
        expect(@contract_one.reload.completion_date).to eq(nil)
      end
    end
  end
end
