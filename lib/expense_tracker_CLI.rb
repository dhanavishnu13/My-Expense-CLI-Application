require 'thor'
require 'pstore'
require 'date'
require 'logger'
# require_relative 'lib/expense_cli'

class ExpenseCLI < Thor
  # Create a logger
  LOGGER = Logger.new('expense.log')
  LOGGER.level = Logger::INFO 

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

  ###################### Helper function ######################

  desc "extract","Extract the expense"
  def extract(expense)
    return "#{expense[:payee].name} - #{expense[:amount]} - #{expense[:date]} - #{expense[:category].name}"
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

  ###################### Main Modules ######################

  desc "add", "Add a new expense"
  def add
    #variable intialization
    payee,amount,date,category='',0.0,'',''
    method='Add'

    puts "Enter Your New Expense Details"
    loop do
      loop do
        payee_name = ask("Enter the payee: ").strip
        if payee_name.empty?
          puts "Please enter the payee name"
          next
        else
          payee = Payee.new(payee_name)
          break
        end
      end

      loop do
        amount = ask("Enter the amount: ").to_f
        if amount <= 0
          puts "Invalid input. Please enter a positive amount."
          next
        else
          break
        end
      end

      loop do
        date = ask("Enter the date (YYYY-MM-DD): ")

        # Validate the date format
        unless date.match?(/\A\d{4}-\d{2}-\d{2}\z/) && date.is_a?(Date)
          puts "Invalid date format. Please use YYYY-MM-DD."
          next
        end

        date = Date.parse(date)
        break
      end

      # Display the categories with their corresponding numbers
      puts "Please choose a category ID from the following list:"
      $categories.each do |category|
        puts "#{category.id} - #{category.name}"
      end

      loop do
        choice = ask("Enter your category: ").to_i    

        # Validate the choice and assign it to a variable
        category = $categories.find { |category| category.id == choice }
        if category.nil?
          puts "Invalid choice. Please enter a valid number."
          next
        else
          puts "You chose #{category.name}"
          break
        end
      end

      expense = { payee: payee, amount: amount, date: date, category: category}

      # Store the expense object in a persistent storage
      store = PStore.new('expense.pstore')
      store.transaction do
        store[:expenses] ||= []
        store[:expenses] << expense
      end
      puts "Added: #{extract(expense)}"

      # Log the addition of an expense
      LOGGER.info("Added: #{extract(expense)}")

      break
    end
  end

  desc "list", "List all expenses"
  def list
    puts "Your Expense Details"
    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:expenses] || []
      if expenses.empty?
        puts "No items in the Expense list."
      else
        expenses.each_with_index do |expense, index|
          if valid_expense?(expense)
            puts "#{index + 1}. #{extract(expense)}"
            LOGGER.info("#{index + 1}. #{extract(expense)}")
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
    begin
      index = ask("Enter the index to remove: ").to_i - 1
      store = PStore.new('expense.pstore')
      store.transaction do
        expenses = store[:expenses] || []

        if expenses.empty?
          puts "No items in the Expense list."
          return
        end

        removed_expense = expenses.delete_at(index)
        store[:expenses] = expenses

        puts "Removed: #{extract(removed_expense)}"

        LOGGER.info("Removed: #{extract(removed_expense)}")
      end
    rescue 
      puts "An error occurred: #{$!}"
      puts "Do you want to retry or cancel? (r/c)"
      answer = ask("Enter your choice: ")
      
      if answer.downcase == "r"
        retry
      elsif answer.downcase == "c"
        puts "Operation cancelled."
        return
      else
        puts "Invalid choice. Please enter r or c."
        retry
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
          category = $categories.find { |category| category.id == choice }
          if category.nil?
            puts "Invalid choice. Please enter a valid number."
            return
          else
            puts "You chose #{category.name}"
          end
        end

        new_expense = { payee: payee, amount: amount, date: date, category: category }
        expenses[index] = new_expense
        store[:expenses] = expenses
        
        puts "Updated expense #{index + 1}: #{extract(old_expense)} -> #{extract(new_expense)}"
        LOGGER.info("Updated expense #{index + 1}: #{extract(old_expense)} -> #{extract(new_expense)}")
      else
        puts "Invalid index. Use 'list' to see the expense indices."
        # Log the error for an invalid index
        LOGGER.error("Invalid index. Use 'list' to see the expense indices.")
      end
    end
  end

  desc "exit_CLI", "Exit the application"
  def exit_CLI
    puts "Exiting ExpenseCLI"
    exit(0)
  end

end

loop do
  puts "ExpenseCLI Options:"
  puts "1. Add an expense"
  puts "2. List all expenses"
  puts "3. Update an expense"
  puts "4. Remove an expense"
  puts "5. Exit"
  puts "Enter your choice: "
  choice = gets.chomp().to_i

  case choice
  when 1
    ExpenseCLI.start(["add"])
  when 2
    ExpenseCLI.start(["list"])
  when 3
    ExpenseCLI.start(["update"])
  when 4
    ExpenseCLI.start(["remove"])
  when 5
    ExpenseCLI.start(["exit_CLI"])
  else
    puts "Invalid choice. Please enter a valid option (1-5)."
  end
end

