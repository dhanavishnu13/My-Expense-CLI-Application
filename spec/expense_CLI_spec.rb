require 'spec_helper'

describe ExpenseCLI do
  let(:cli) { ExpenseCLI.new }

  describe '#valid_expense?' do
    it 'returns true for a valid expense' do
      expense = {
        payee: ExpenseCLI::Payee.new('John Doe'),
        amount: 100.0,
        date: Date.parse('2023-10-19'),
        category: ExpenseCLI::Category.new('food', 1)
      }
      expect(cli.valid_expense?(expense)).to be(true)
    end

    it 'returns false for an invalid expense' do
      expense = { invalid: 'data' }
      expect(cli.valid_expense?(expense)).to be(false)
    end
  end

  describe '#extract' do
    it 'returns the formatted expense string' do
      expense = {
        payee: ExpenseCLI::Payee.new('Alice Smith'),
        amount: 50.0,
        date: Date.parse('2023-10-20'),
        category: ExpenseCLI::Category.new('entertainment', 4)
      }
      formatted_expense = 'Alice Smith - 50.0 - 2023-10-20 - entertainment'
      expect(cli.extract(expense)).to eq(formatted_expense)
    end
  end
end
