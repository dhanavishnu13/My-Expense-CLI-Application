require 'thor'
require 'pstore'

class TodoCLI < Thor
  desc "add TASK", "Add a new task to the to-do list"
  def add(task)
    store = PStore.new('todo.pstore')
    store.transaction do
      store[:tasks] ||= []
      store[:tasks] << task
    end
    puts "Added: #{task}"
  end

  desc "list", "List all tasks"
  def list
    store = PStore.new('todo.pstore')
    store.transaction do
      tasks = store[:tasks] || []
      if tasks.empty?
        puts "No tasks in the to-do list."
      else
        tasks.each_with_index do |task, index|
          puts "#{index + 1}. #{task}"
        end
      end
    end
  end

  desc "remove INDEX", "Remove a task by its index"
  def remove(index)
    index = index.to_i - 1
    store = PStore.new('todo.pstore')
    store.transaction do
      tasks = store[:tasks] || []
      if index >= 0 && index < tasks.length
        removed_task = tasks.delete_at(index)
        store[:tasks] = tasks
        puts "Removed: #{removed_task}"
      else
        puts "Invalid index. Use 'list' to see the task indices."
      end
    end
  end

  desc "update INDEX TASK", "Update a task by its index"
  def update(index, task)
    index = index.to_i - 1
    store = PStore.new('todo.pstore')
    store.transaction do
      tasks = store[:tasks] || []
      if index >= 0 && index < tasks.length
        old_task = tasks[index]
        tasks[index] = task
        store[:tasks] = tasks
        puts "Updated task #{index + 1}: #{old_task} -> #{task}"
      else
        puts "Invalid index. Use 'list' to see the task indices."
      end
    end
  end
end

TodoCLI.start
