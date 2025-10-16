# frozen_string_literal: true

# Sample User model for testing The Mechanic engine
# This demonstrates that benchmark code can access host application models
class User
  attr_accessor :first_name, :last_name, :email
  
  def initialize(first_name:, last_name:, email:)
    @first_name = first_name
    @last_name = last_name
    @email = email
  end
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def full_name_reverse
    "#{last_name}, #{first_name}"
  end
  
  # Class method for testing
  def self.sample_users
    [
      new(first_name: 'John', last_name: 'Doe', email: 'john@example.com'),
      new(first_name: 'Jane', last_name: 'Smith', email: 'jane@example.com'),
      new(first_name: 'Bob', last_name: 'Johnson', email: 'bob@example.com')
    ]
  end
end
