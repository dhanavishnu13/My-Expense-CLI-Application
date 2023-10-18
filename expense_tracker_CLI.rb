require 'thor'
require 'pstore'
require 'date'
require 'logger'

class ExpenseCLI < Thor
  # Create a logger
  LOGGER = Logger.new('expense.log')
  LOGGER.level = Logger::INFO # Adjust the log level as needed (e.g., Logger::DEBUG)

  $categories = {
    food: 1,
    rent: 2,
    transportation: 3,
    entertainment: 4,
    other: 5
  }

  desc "add", "Add a new expense"
  def add
    payee = ask("Enter the payee: ")
    amount = ask("Enter the amount: ").to_f
    # date = ask("Enter the date (YYYY-MM-DD): ")
    date = Date.today

    # Display the categories with their corresponding numbers
    puts "Please choose a category from the following list:"
    $categories.each do |key, value|
      puts "#{value} - #{key}"
    end

    # Ask the user for their choice and convert it to an integer
    choice = ask("Enter your category: ").to_i

    # # Validate the date format
    # unless date.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    #   puts "Invalid date format. Please use YYYY-MM-DD."
    #   return
    # end

    # date = Date.parse(date)

    if amount <= 0
      puts "Invalid input. Please enter a positive amount."
      return
    end

    # Validate the choice and assign it to a variable
    if $categories.values.include?(choice)
      category = $categories.key(choice)
      puts "You chose #{category}"
    else
      puts "Invalid choice. Please enter a valid number."
    end

    expense = { payee: payee, amount: amount, date: date, category: $categories.key(choice)}
    # Store the expense object in a persistent storage
    store = PStore.new('expense.pstore')
    store.transaction do
      store[:expenses] ||= []
      store[:expenses] << expense
    end
    puts "Added: #{expense[:payee]} - #{expense[:amount]} - #{expense[:date]} - #{expense[:category]}"
    # Log the addition of an expense
    LOGGER.info("Added: #{expense[:payee]} - #{expense[:amount]} - #{expense[:date]}")
  end

  desc "list", "List all expenses"
  def list
    # Retrieve the expenses from the persistent storage
    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:expenses] || []
      if expenses.empty?
        puts "No items in the Expense list."
      else
        # Print each expense with its index, payee, amount, and date
        expenses.each_with_index do |expense, index|
          if expense.is_a?(Hash) && expense.key?(:payee) && expense.key?(:amount) && expense.key?(:date)
            puts "#{index + 1}. #{expense[:payee]} - #{expense[:amount]} - #{expense[:date]} - #{expense[:category]}"
          else
            puts "Expense at index #{index} is not properly formatted."
            LOGGER.error("Expense at index #{index} is not properly formatted.")
          end
        end
      end
    end
  end


  desc "remove", "Remove an expense by its index"
  def remove
    list
    index = ask("Enter the index to remove: ").to_i - 1
    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:expenses] || []

      if expenses.empty?
        puts "No items in the Expense list."
        return
      end

      if index >= 0 && index < expenses.length
        removed_expense = expenses.delete_at(index)
        store[:expenses] = expenses
        puts "Removed: #{removed_expense[:payee]} - #{removed_expense[:amount]} - #{removed_expense[:date]} - #{removed_expense[:category]}"
      else
        puts "Invalid index. Use 'list' to see the expense indices."
        # Log the error for an invalid index
        LOGGER.error("Invalid index. Use 'list' to see the expense indices.")
      end
    end
  end


  desc "update", "Update an expense by its index"
  def update
    list
    index = ask("Enter the index to update: ").to_i - 1
    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:expenses] || []

      if expenses.empty?
        puts "No items in the Expense list."
        return
      end

      if index >= 0 && index < expenses.length
        old_expense = expenses[index]

        payee = ask("Enter the new payee (leave empty to keep '#{old_expense[:payee]}'): ")
        amount = ask("Enter the new amount (leave empty to keep '#{old_expense[:amount]}'): ").to_f
        date = ask("Enter the new date (YYYY-MM-DD, leave empty to keep '#{old_expense[:date]}'): ")
        # Display the categories with their corresponding numbers
        puts "Please choose a category from the following list:"
        $categories.each do |key, value|
          puts "#{value} - #{key}"
        end

        # Ask the user for their choice and convert it to an integer
        choice = ask("Enter new category (leave empty to keep '#{old_expense[:category]}'): ").to_i



        # Validate and update attributes
        payee = old_expense[:payee] if payee.empty?
        amount = old_expense[:amount] if amount <= 0
        date = Date.parse(date) if date.match?(/\A\d{4}-\d{2}-\d{2}\z/)

        # Validate the choice and assign it to a variable
        if $categories.values.include?(choice)
          category = $categories.key(choice)
          puts "You chose #{category}"
        else
          puts "Invalid choice. Please enter a valid number."
        end

        new_expense = { payee: payee, amount: amount, date: date, category: $categories.key(choice) }
        expenses[index] = new_expense
        store[:expenses] = expenses

        puts "Updated expense #{index + 1}: #{old_expense[:payee]} - #{old_expense[:amount]} - #{old_expense[:date]} - #{old_expense[:category]} -> #{new_expense[:payee]} - #{new_expense[:amount]} - #{new_expense[:date]} - #{new_expense[:category]}"
      else
        puts "Invalid index. Use 'list' to see the expense indices."
        # Log the error for an invalid index
        LOGGER.error("Invalid index. Use 'list' to see the expense indices.")
      end
    end
  end

end

ExpenseCLI.start

