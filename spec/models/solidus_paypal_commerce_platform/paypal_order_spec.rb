# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusPaypalCommercePlatform::PaypalOrder, type: :model do
  describe '#to_json' do
    subject(:to_json) { described_class.new(order).to_json('intent') }

    let(:order) { create(:order_ready_to_complete, ship_address: ship_address, bill_address: bill_address) }
    let(:ship_address) { create_address('John', 'Von Doe') }
    let(:bill_address) { create_address('Johnny', 'Vonny Doey') }

    it { expect { to_json }.not_to raise_error }

    it 'maps the bill and ship address names correctly' do
      expect(to_json).to match hash_including(
        purchase_units: array_including(
          hash_including(shipping: hash_including(name: { full_name: 'John Von Doe' }))
        ),
        payer: hash_including(name: { given_name: 'Johnny', surname: 'Vonny Doey' })
      )
    end

    context 'when checkout_steps does not include "delivery"' do
      let(:old_checkout_flow) { Spree::Order.checkout_flow }

      before do
        old_checkout_flow

        Spree::Order.class_eval do
          remove_checkout_step :delivery
        end
      end

      after do
        Spree::Order.checkout_flow(&old_checkout_flow)
      end

      it 'disable shipping requirements' do
        expect(to_json).to match hash_including(
          application_context: hash_including(shipping_preference: 'NO_SHIPPING')
        )
      end
    end
  end

  private

  def create_address(firstname, lastname)
    create(:address, name: "#{firstname} #{lastname}")
  end
end
