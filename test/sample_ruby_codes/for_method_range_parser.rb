module Everywhere
  def bagel!
    puts "Bagel bagel bagel"
  end
end

class EverythingAllAtOnce < HashBrown
  EXAMPLE_CONSTANT = "ok"

  include Everywhere

  def self.class_method(arg1 = "nope", arg2: "nope")
    puts "class method"
    puts "somemore"
  end

  def whatever(arg1 = "nope", arg2: "nope")
    # def whenever(arg1 = "nope", arg2: "nope")
    #   puts "puts from whenever"
    # end

    whenever

    loop {
      puts "Ouch"
      next
    }
  end

  def rails_controller_lineless
  end
end
