# Define the categories hash
categories = {
    food: 1,
    rent: 2,
    transportation: 3,
    entertainment: 4,
    other: 5
  }
  
  # Display the categories with their corresponding numbers
  puts "Please choose a category from the following list:"
  categories.each do |key, value|
    puts "#{value} - #{key}"
  end
  
  # Ask the user for their choice and convert it to an integer
  choice = gets.to_i
  
  # Validate the choice and assign it to a variable
  if categories.values.include?(choice)
    category = categories.key(choice)
    puts "You chose #{category}"
  else
    puts "Invalid choice. Please enter a valid number."
  end
  