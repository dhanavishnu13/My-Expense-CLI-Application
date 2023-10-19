require 'payee'

describe Payee do
    it "check payee name" do
        name=Payee.new("   ")
        valid_name=name.validate
        expect(valid_name)        
    end

end
