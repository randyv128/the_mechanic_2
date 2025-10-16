# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TheMechanic2::SecurityService do
  describe '.validate' do
    context 'with empty or nil code' do
      it 'returns invalid for nil code' do
        result = described_class.validate(nil)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Code cannot be empty')
      end
      
      it 'returns invalid for empty string' do
        result = described_class.validate('')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Code cannot be empty')
      end
      
      it 'returns invalid for whitespace only' do
        result = described_class.validate('   ')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Code cannot be empty')
      end
    end
    
    context 'with system calls' do
      it 'detects system() calls' do
        code = 'system("ls -la")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('System calls detected')
      end
      
      it 'detects exec() calls' do
        code = 'exec("rm -rf /")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('System calls detected')
      end
      
      it 'detects spawn() calls' do
        code = 'spawn("malicious command")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('System calls detected')
      end
      
      it 'detects backtick commands' do
        code = '`cat /etc/passwd`'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('System calls detected')
      end
      
      it 'detects %x{} syntax' do
        code = '%x{whoami}'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('System calls detected')
      end
      
      it 'detects fork calls' do
        code = 'fork do; puts "child"; end'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('System calls detected')
      end
      
      it 'detects Process.spawn' do
        code = 'Process.spawn("ls")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('System calls detected')
      end
    end
    
    context 'with file operations' do
      it 'detects File.open' do
        code = 'File.open("/etc/passwd", "r")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('File operations detected')
      end
      
      it 'detects File.read' do
        code = 'File.read("/etc/passwd")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('File operations detected')
      end
      
      it 'detects File.write' do
        code = 'File.write("malicious.txt", "data")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('File operations detected')
      end
      
      it 'detects File.delete' do
        code = 'File.delete("important.txt")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('File operations detected')
      end
      
      it 'detects FileUtils operations' do
        code = 'FileUtils.rm_rf("/")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('File operations detected')
      end
      
      it 'detects IO.read' do
        code = 'IO.read("/etc/passwd")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('File operations detected')
      end
      
      it 'detects Kernel#open' do
        code = 'open("file.txt")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('File operations detected')
      end
    end
    
    context 'with network operations' do
      it 'detects Net::HTTP' do
        code = 'Net::HTTP.get(URI("http://example.com"))'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Network operations detected')
      end
      
      it 'detects Socket operations' do
        code = 'Socket.tcp("example.com", 80)'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Network operations detected')
      end
      
      it 'detects TCPSocket' do
        code = 'TCPSocket.new("example.com", 80)'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Network operations detected')
      end
      
      it 'detects URI.open' do
        code = 'URI.open("http://example.com")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Network operations detected')
      end
    end
    
    context 'with database write operations' do
      it 'detects .save calls' do
        code = 'user.save'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Database writes detected')
      end
      
      it 'detects .save! calls' do
        code = 'user.save!'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Database writes detected')
      end
      
      it 'detects .update calls' do
        code = 'user.update(name: "New Name")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Database writes detected')
      end
      
      it 'detects .destroy calls' do
        code = 'user.destroy'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Database writes detected')
      end
      
      it 'detects .delete calls' do
        code = 'User.delete(1)'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Database writes detected')
      end
      
      it 'detects .create calls' do
        code = 'User.create(name: "Test")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Database writes detected')
      end
      
      it 'detects .update_all' do
        code = 'User.update_all(active: false)'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Database writes detected')
      end
      
      it 'detects .destroy_all' do
        code = 'User.destroy_all'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Database writes detected')
      end
    end
    
    context 'with dangerous eval operations' do
      it 'detects eval calls' do
        code = 'eval("malicious code")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Dangerous evals detected')
      end
      
      it 'detects instance_eval' do
        code = 'obj.instance_eval("@secret = nil")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Dangerous evals detected')
      end
      
      it 'detects class_eval' do
        code = 'User.class_eval("def hack; end")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Dangerous evals detected')
      end
      
      it 'detects send calls' do
        code = 'obj.send(:private_method)'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Dangerous evals detected')
      end
      
      it 'detects const_set' do
        code = 'Object.const_set(:HACK, "value")'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Dangerous evals detected')
      end
    end
    
    context 'with thread operations' do
      it 'detects Thread.new' do
        code = 'Thread.new { puts "background" }'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Thread operations detected')
      end
      
      it 'detects Thread.start' do
        code = 'Thread.start { loop { } }'
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].first).to include('Thread operations detected')
      end
    end
    
    context 'with safe operations' do
      it 'allows simple arithmetic' do
        code = '1 + 2 + 3'
        result = described_class.validate(code)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
      
      it 'allows string operations' do
        code = '"hello".upcase + " world"'
        result = described_class.validate(code)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
      
      it 'allows array operations' do
        code = '[1, 2, 3].map { |n| n * 2 }.sum'
        result = described_class.validate(code)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
      
      it 'allows hash operations' do
        code = '{ a: 1, b: 2 }.transform_values { |v| v * 2 }'
        result = described_class.validate(code)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
      
      it 'allows ActiveRecord queries (read-only)' do
        code = 'User.where(active: true).count'
        result = described_class.validate(code)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
      
      it 'allows method calls on objects' do
        code = 'user.full_name'
        result = described_class.validate(code)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
      
      it 'allows variable assignments' do
        code = 'x = 10; y = 20; x + y'
        result = described_class.validate(code)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
    end
    
    context 'with multiple violations' do
      it 'returns all detected errors' do
        code = <<~RUBY
          system("ls")
          File.read("/etc/passwd")
          user.save
        RUBY
        
        result = described_class.validate(code)
        expect(result[:valid]).to be false
        expect(result[:errors].length).to be >= 3
      end
    end
  end
end
