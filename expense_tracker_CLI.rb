require 'thor'
require 'pstore'

class TodoCLI < Thor
  desc "add", "Add a new expense to the Expense list"
  def add(expense)
    store = PStore.new('expense.pstore')
    store.transaction do
      store[:items] ||= []
      store[:items] << expense
    end
    puts "Added: #{expense}"
  end

  desc "list", "List all expenses"
  def list
    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:items] || []
      if expenses.empty?
        puts "No item in the Expense list."
      else
        expenses.each_with_index do |item, index|
          puts "#{index + 1}. #{item}"
        end
      end
    end
  end

  desc "remove", "Remove a expense by its index"
  def remove(index)
    index = index.to_i - 1
    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:expenses] || []
      puts expenses.length
      if index >= 0 && index < expenses.length
        removed_expense = expenses.delete_at(index)
        store[:expenses] = expenses
        puts "Removed: #{removed_expense}"
      else
        puts "Invalid index. Use 'list' to see the task indices."
      end
    end
  end

  desc "update", "Update a expense by its index"
  def update(index, expense)
    index = index.to_i - 1
    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:expenses] || []
      if index >= 0 && index < expenses.length
        old_expense = expenses[index]
        expenses[index] = expense
        store[:tasks] = expenses
        puts "Updated task #{index + 1}: #{old_expense} -> #{expense}"
      else
        puts "Invalid index. Use 'list' to see the task indices."
      end
    end
  end
end

TodoCLI.start
