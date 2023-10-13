require "thor"
require "pstore"

class TODOApp < Thor
    desc "add_task NAME", "Add a new task to your TODO list"

    def add_task(name)
        PStore.new("task.txt").transaction {|store| store[name]=true}
    end

    desc "delete_task NAME", "Remove a task to your TODO list"

    def delete_task(name)
        PStore.new("task.txt").transaction {|store| store.delete(name)}
    end

    desc "list_task", "List allyour tasks in TODO list"

    def list_task
        PStore.new("task.txt").transaction do |store|
            store.roots.each_with_index {|task, idx| puts "#{idx+1}. #{task}"} 
        end
    end

    desc "update_task", "Update your tasks in TODO list"

    def update_task(id, new_task)
        id= id.to_i-1
        # Create a PStore object with the file name
        store = PStore.new("task.txt")
        # Start a transaction to modify the file
        store.transaction do
          # Loop through all the tasks in the file
          store.roots.each_with_index do |task, idx|
            # If the current index matches the id parameter
            if id == idx
              # Update the task with the new_task parameter
              store[idx] = new_task
            end
          end
        end
      end
end

TODOApp.start(ARGV)
