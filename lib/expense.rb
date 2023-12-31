require 'thor'
require 'pstore'
require 'date'
require 'logger'
require_relative 'payee'
require_relative 'category'
# require_relative 'lib/expense_cli'

class Expense < Thor
  # Create a logger
  LOGGER = Logger.new('expense.log')
  LOGGER.level = Logger::INFO 

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
  # desc "validate","Validate the expense"
  # def valid_expense?(expense)
  #   expense.is_a?(Hash) && 
  #   expense.key?(:payee) && expense[:payee].is_a?(Payee) &&
  #   expense.key?(:amount) && expense[:amount].is_a?(Numeric) &&
  #   expense.key?(:date) && expense[:date].is_a?(Date) &&
  #   expense.key?(:category) && expense[:category].is_a?(Category)
  # end

  ###################### Main Modules ######################

  desc "add", "Add a new expense"
  def add
    n=30
    n.times { print ">"}
    print " Add MyExpense "
    n.times { print "<"}
    print "\n"
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
        unless date.match?(/\A\d{4}-\d{2}-\d{2}\z/) 
          begin
            date = Date.parse(date)
            break
          rescue ArgumentError
            puts "Invalid date format. Please use YYYY-MM-DD."
            next
          end
        end
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
    n=30
    n.times { print ">"}
    print " List MyExpense "
    n.times { print "<"}
    print "\n"

    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:expenses] || []
      if expenses.empty?
        puts "No items in the Expense list."
      else
        expenses.each_with_index do |expense, index|
          # if valid_expense?(expense)
          puts "#{index + 1}. #{extract(expense)}"
          LOGGER.info("#{index + 1}. #{extract(expense)}")
          # else
          #   puts "Expense at index #{index} is not properly formatted."
          #   LOGGER.error("Expense at index #{index} is not properly formatted.")
          # end
        end
      end
    end
  end

  desc "remove", "Remove an expense by its index"
  def remove
    n=30
    n.times { print ">"}
    print " Remove MyExpense "
    n.times { print "<"}
    print "\n"
    list
    begin
      store = PStore.new('expense.pstore')
      store.transaction do
        expenses = store[:expenses] || []
        if expenses.empty?
          puts "No items in the Expense list."
          return
        end

        index = ask("Enter the index to remove: ").to_i - 1
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
    n=30
    n.times { print ">"}
    print " Update MyExpense "
    n.times { print "<"}
    print "\n"
    #variable intialization
    payee,amount,date,category='',0.0,'',''
    list
    
    store = PStore.new('expense.pstore')
    store.transaction do
      expenses = store[:expenses] || []

      if expenses.empty?
        puts "No items in the Expense list."
        return
      else
        loop do
          index = ask("(Enter '0' to exit)Enter the index to update: ").to_i - 1
          if index==-1
            return
          elsif index >= 0 && index < expenses.length
            old_expense = expenses[index]
            
            payee = ask("Enter the new payee (leave empty to keep '#{old_expense[:payee].name}'): ").strip
            # Validate and update attributes
            if payee.empty?
              payee = old_expense[:payee] 
            else
              payee = Payee.new(payee)
            end
          
            amount = ask("Enter the new amount (leave empty to keep '#{old_expense[:amount]}'): ").to_f
            amount = old_expense[:amount] if amount <= 0

            loop do
              date = ask("Enter the new date (YYYY-MM-DD, leave empty to keep '#{old_expense[:date]}'): ")
              if date.empty?
                date=old_expense[:date]
                break
              else
                if date.match?(/\A\d{4}-\d{2}-\d{2}\z/)
                  date = Date.parse(date) 
                  break
                else
                  puts "Invalid date format. Please use YYYY-MM-DD."
                  next
                end
              end
            end

            # Display the categories with their corresponding numbers
            puts "Please choose a category ID from the following list:"
            $categories.each do |category|
              puts "#{category.id} - #{category.name}"
            end
            loop do
              # Ask the user for their choice and convert it to an integer
              choice = ask("Enter new category (leave empty to keep '#{old_expense[:category].id}'): ")

              # Validate the choice and assign it to a variable
              if choice.empty?
                category= old_expense[:category]
                break
              else
                category = $categories.find { |category| category.id == choice.to_i }
                if category.nil?
                  puts "Invalid choice. Please enter a valid number."
                  next
                else
                  puts "You chose #{category.name}"
                  break
                end
              end
            end

            new_expense = { payee: payee, amount: amount, date: date, category: category }
            expenses[index] = new_expense
            store[:expenses] = expenses
            store.commit
            puts "Updated expense #{index + 1}: #{extract(old_expense)} -> #{extract(expenses[index])}"
            LOGGER.info("Updated expense #{index + 1}: #{extract(old_expense)} -> #{extract(expenses[index])}")
            break
          else
            puts "Invalid index. Use 'list' to see the expense indices."
            # Log the error for an invalid index
            LOGGER.error("Invalid index. Use 'list' to see the expense indices.")
            next
          end
        end
      end
    end
    list
  end

  desc "exit_CLI", "Exit the application"
  def exit_CLI
    puts "Exiting ExpenseCLI"
    exit(0)
  end

end

loop do
  n=30
  n.times { print ">"}
  print " MyExpense "
  n.times { print "<"}
  print "\n"
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
    Expense.start(["add"])
  when 2
    Expense.start(["list"])
  when 3
    Expense.start(["update"])
  when 4
    Expense.start(["remove"])
  when 5
    Expense.start(["exit_CLI"])
  else
    puts "Invalid choice. Please enter a valid option (1-5)."
  end
end

