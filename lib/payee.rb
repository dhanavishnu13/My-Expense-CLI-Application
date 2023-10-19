# Create a class for payee
class Payee
    attr_accessor :name


    def initialize(name)
      @name = name
    end

    def validate
        if name.strip.empty?
            return false
        end
        return true
    end
end
