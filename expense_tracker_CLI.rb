require 'thor'
require 'pstore'
require 'date'
require 'logger'

class ExpenseCLI < Thor
  # Create a logger
  LOGGER = Logger.new('expense.log')
  LOGGER.level = Logger::INFO # Adjust the log level as needed (e.g., Logger::DEBUG)

  # Create a class for payee
  class Payee
    attr_accessor :name

    def initialize(name)
      @name = name
    end
  end

  # Create a class for category
  class Category
    attr_accessor :name, :id

    def initialize(name, id)
      @name = name
      @id = id
    end
  end

  # Create an array of categories with their corresponding numbers
  $categories = [
    Category.new("food", 1),
    Category.new("rent", 2),
    Category.new("transportation", 3),
    Category.new("entertainment", 4),
    Category.new("other", 5)
  ]

  desc "add", "Add a new expense"
  def add
    payee_name = ask("Enter the payee: ")
    payee = Payee.new(payee_name) # Create a payee object with the given name
    amount = ask("Enter the amount: ").to_f
    if amount <= 0
      puts "Invalid input. Please enter a positive amount."
      return
    end
    date = ask("Enter the date (YYYY-MM-DD): ")
    # date = Date.today

    # Validate the date format
    unless date.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      puts "Invalid date format. Please use YYYY-MM-DD."
      return
    end

    date = Date.parse(date)

    # Display the categories with their corresponding numbers
    puts "Please choose a category ID from the following list:"
    $categories.each do |category|
      puts "#{category.id} - #{category.name}"
    end

    # Ask the user for their choice and convert it to an integer
    choice = ask("Enter your category: ").to_i    

    # Validate the choice and assign it to a variable
    category = $categories.find { |category| category.id == choice } # Find the category object that matches the choice
    if category.nil?
      puts "Invalid choice. Please enter a valid number."
      return
    else
      puts "You chose #{category.name}"
    end

    expense = { payee: payee, amount: amount, date: date, category: category}
    
    # Store the expense object in a persistent storage
    store = PStore.new('expense.pstore')
    store.transaction do
      store[:expenses] ||= []
      store[:expenses] << expense
    end
    
    puts "Added: #{expense[:payee].name} - #{expense[:amount]} - #{expense[:date]} - #{expense[:category].name}"
    
    # Log the addition of an expense
    LOGGER.info("Added: #{expense[:payee].name} - #{expense[:amount]} - #{expense[:date]}")
  end

  # Define a separate function to check if an expense is valid
  desc "validate","Validate the expense"
  def valid_expense?(expense)
    expense.is_a?(Hash) && 
    expense.key?(:payee) && expense[:payee].is_a?(Payee) &&
    expense.key?(:amount) && expense[:amount].is_a?(Numeric) &&
    expense.key?(:date) && expense[:date].is_a?(Date) &&
    expense.key?(:category) && expense[:category].is_a?(Category)
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
        # Print each expense with its index, payee, amount, date, and category
        expenses.each_with_index do |expense, index|
          if valid_expense?(expense)
            # Use the name attribute of the payee and category objects to display them
            puts "#{index + 1}. #{expense[:payee].name} - #{expense[:amount]} - #{expense[:date]} - #{expense[:category].name}"
            LOGGER.info("#{index + 1}. #{expense[:payee].name} - #{expense[:amount]} - #{expense[:date]} - #{expense[:category].name}")
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
        puts "Removed: #{removed_expense[:payee].name} - #{removed_expense[:amount]} - #{removed_expense[:date]} - #{removed_expense[:category].name}"
        LOGGER.info("Removed: #{removed_expense[:payee].name} - #{removed_expense[:amount]} - #{removed_expense[:date]} - #{removed_expense[:category].name}")
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

        payee = ask("Enter the new payee (leave empty to keep '#{old_expense[:payee].name}'): ")
        # Validate and update attributes
        payee = old_expense[:payee] if payee.empty?

        amount = ask("Enter the new amount (leave empty to keep '#{old_expense[:amount]}'): ").to_f
        amount = old_expense[:amount] if amount <= 0

        date = ask("Enter the new date (YYYY-MM-DD, leave empty to keep '#{old_expense[:date]}'): ")
        if date.empty?
          date=old_expense[:date]
        else
          date = Date.parse(date) if date.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        end

        # Display the categories with their corresponding numbers
        puts "Please choose a category ID from the following list:"
        $categories.each do |category|
          puts "#{category.id} - #{category.name}"
        end

        # Ask the user for their choice and convert it to an integer
        choice = ask("Enter new category (leave empty to keep '#{old_expense[:category].id}'): ").to_i

        # Validate the choice and assign it to a variable
        if choice==0
          category= old_expense[:category]
        else
          category = $categories.find { |category| category.id == choice } # Find the category object that matches the choice
          if category.nil?
            puts "Invalid choice. Please enter a valid number."
            return
          else
            puts "You chose #{category.name}"
          end
        end

        new_expense = { payee: payee, amount: amount, date: date, category: category.name }
        expenses[index] = new_expense
        store[:expenses] = expenses

        puts "Updated expense #{index + 1}: #{old_expense[:payee].name} - #{old_expense[:amount]} - #{old_expense[:date]} - #{old_expense[:category].name} -> #{new_expense[:payee].name} - #{new_expense[:amount]} - #{new_expense[:date]} - #{new_expense[:category]}"
        LOGGER.info("Updated expense #{index + 1}: #{old_expense[:payee].name} - #{old_expense[:amount]} - #{old_expense[:date]} - #{old_expense[:category].name} -> #{new_expense[:payee].name} - #{new_expense[:amount]} - #{new_expense[:date]} - #{new_expense[:category]}")
      else
        puts "Invalid index. Use 'list' to see the expense indices."
        # Log the error for an invalid index
        LOGGER.error("Invalid index. Use 'list' to see the expense indices.")
      end
    end
  end

end

ExpenseCLI.start

