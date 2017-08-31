class ContractsController < ApplicationController

  def index
    if current_customer && current_customer.contracts.any?
      contracts = current_customer.contracts
    elsif current_company && current_company.contracts.any?
      contracts = current_company.contracts
    else
      redirect_to '/'
    end
    @completed_contracts = get_contracts_by_status(contracts, :complete)
    @active_contracts = get_contracts_by_status(contracts, :active)
  end

  def create
    accepted_quote = Quote.find(params[:contract][:quote_id])
    customer_request = accepted_quote.customer_request
    if current_customer.customer_requests.include?(customer_request)
      if Contract.create(
        quote_id: accepted_quote.id,
        customer_request_id: customer_request.id
      )
        if accepted_quote.update(accepted: true)
          customer_request.quotes.each do |quote|
            if quote.accepted
              CompanyMailer.accept_email(quote).deliver_now
            else
              CompanyMailer.decline_email(quote).deliver_now
              quote.update(accepted: false)
            end
          end
        end
      flash[:notice] = "Contract created and saved!"
      redirect_to '/quotes'
      else
        flash[:notice] = "Quote was not accepted. Try again. #{@quote.errors.full_messages.join(', ')}."
        redirect_to "/quotes/#{@quote.id}"
      end
    end
  end

  def show
    if current_customer || current_company
      @contract = Contract.find(params[:id])
      render 'show.html.erb'
    else
      redirect_to '/'
    end
  end

  private

  def get_contracts_by_status(contracts, status)
    if status == :active
      contracts = contracts.select { |contract| contract.completion_date.nil? }
    elsif status == :complete
      contracts = contracts.select { |contract| contract.completion_date.present? }
    end
    contracts
  end
end
