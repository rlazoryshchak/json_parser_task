# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'bigdecimal'
require 'bigdecimal/util'
require "active_support/core_ext/date"
require "rspec/autorun"

# Ruby 2.3
class JsonParser
	LINK = 'https://pkgstore.datahub.io/cryptocurrency/bitcoin/bitcoin_json/data/3d47ebaea5707774cb076c9cd2e0ce8c/bitcoin_json.json'
	METHODS_MAPPING = {
		weekly: :beginning_of_week,
		monthly: :beginning_of_month,
		quarterly: :beginning_of_quarter
	}

	attr_reader :data, :order_dir, :filter_date_from, :filter_date_to, :granularity

  def initialize(order_dir: :desc, filter_date_from: nil, filter_date_to: nil, granularity: :daily)
    @data = JSON.load(open(LINK))
    @order_dir = order_dir
    @filter_date_from = filter_date_from.nil? ? nil : Date.parse(filter_date_from.to_s)
    @filter_date_to = filter_date_to.nil? ? nil : Date.parse(filter_date_to.to_s)
    @granularity = granularity
  end

  def self.call(*args)
  	new(*args).call
  end

  def call
  	ranging
  	sorting
  	grouping
  	formating
  end

  private

  def formating
  	@data = data.inject([]) do |acc, h|
      acc << [h['date'], h['price(USD)']]
      acc
    end
  end
  
  def ranging  
    @data = data.select do |h| 
    	if !filter_date_from.nil? && !filter_date_to.nil?
    		Date.parse(h['date']).between? filter_date_from, filter_date_to
    	elsif !filter_date_from.nil?
    		Date.parse(h['date']) >= filter_date_from
    	elsif !filter_date_to.nil?
    		Date.parse(h['date']) <= filter_date_to
    	else
    	  true
    	end  	
    end
  end

  def grouping
  	return data if granularity == :daily

    date_method = METHODS_MAPPING[granularity]

    @data = data.inject({}) do |acc, d|
    	day = Date.parse(d['date']).public_send(date_method)
    	price = BigDecimal(d['price(USD)'].to_s)

      acc[day].nil? ? acc[day] = [price] : acc[day] << price
      	 
    	acc
    end.map do |day, prices|
    	{ 
    		'date' => day.to_s, 
    		'price(USD)' => (prices.inject(0,:+) / prices.size).round(2).to_digits
    	}
    end	
  end

  def sorting
  	@data = data.sort do |a, b| 
    	order_dir == :desc ? b['date'] <=> a['date'] : a['date'] <=> b['date']
    end
  end
end

describe JsonParser do
	let(:data) do
		[
			{
				'date' => '2018-10-01',
				'price(USD)' => '3321.71'
			},
			{
				'date' => '2018-09-30',
				'price(USD)' => '3320.7'
			},
			{
				'date' => '2018-10-02',
				'price(USD)' => '3322.72'
			},
			{
				'date' => '2018-10-03',
				'price(USD)' => '3323.73'
			}
		]
	end

  # Could be used VCR instead og mock open-uri
  before { allow_any_instance_of(Kernel).to receive_message_chain(:open).and_return(data.to_json) }

  context 'sorting' do
  	let(:desc_data) do
  		[
        ["2018-10-03", "3323.73"], 
        ["2018-10-02", "3322.72"], 
        ["2018-10-01", "3321.71"], 
        ["2018-09-30", "3320.7"]
  		]
  	end

	  it 'in desc order by default' do
	  	expect(subject.call).to eq desc_data
	  end

	  it 'in asc order' do
	  	expect(JsonParser.call(order_dir: :asc)).to eq desc_data.reverse
	  end
	end

	context 'filtering' do
		let(:filtered_data) do
  		[
        ["2018-10-02", "3322.72"], 
        ["2018-10-01", "3321.71"]
  		]
  	end

		it 'returns data from 2018-10-01 to 2018-10-02' do
	  	expect(
	  		JsonParser.call(
	  			filter_date_from: "2018-10-01", 
	  			filter_date_to: Date.parse("2018-10-02")
	  		)
	  	).to eq filtered_data
	  end
	end

	context 'granularity' do
		it 'returns weekly data' do
	  	expect(JsonParser.call(granularity: :weekly)).to eq [["2018-10-01", "3322.72"], ["2018-09-24", "3320.7"]]
	  end

	  it 'returns quarterly data' do
	  	expect(JsonParser.call(granularity: :quarterly)).to eq [["2018-10-01", "3322.72"], ["2018-07-01", "3320.7"]]
	  end

	  it 'returns monthly data' do
	  	expect(JsonParser.call(granularity: :monthly)).to eq [["2018-10-01", "3322.72"], ["2018-09-01", "3320.7"]]
	  end
	end
end