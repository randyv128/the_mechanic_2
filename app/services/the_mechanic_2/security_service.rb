# frozen_string_literal: true

module TheMechanic2
  # Service for validating Ruby code before execution
  # Blocks dangerous operations like system calls, file I/O, network access, etc.
  class SecurityService
    # Forbidden patterns that should not be allowed in benchmark code
    FORBIDDEN_PATTERNS = {
      system_calls: [
        /\bsystem\s*\(/,
        /\bexec\s*\(/,
        /\bspawn\s*\(/,
        /`[^`]+`/,  # backticks
        /\%x\{/,    # %x{} syntax
        /\bfork\s*(\(|do|\{)/,
        /Process\.spawn/,
        /Process\.exec/,
        /Kernel\.system/,
        /Kernel\.exec/,
        /Kernel\.spawn/
      ],
      network_operations: [
        /URI\.open/,  # Check this first before generic open
        /Net::HTTP/,
        /Net::FTP/,
        /Net::SMTP/,
        /Net::POP3/,
        /Net::IMAP/,
        /Socket\./,
        /TCPSocket/,
        /UDPSocket/,
        /UNIXSocket/,
        /HTTParty/,
        /Faraday/,
        /RestClient/
      ],
      file_operations: [
        /File\.open/,
        /File\.read/,
        /File\.write/,
        /File\.delete/,
        /File\.unlink/,
        /File\.rename/,
        /File\.chmod/,
        /File\.chown/,
        /FileUtils\./,
        /IO\.read/,
        /IO\.write/,
        /IO\.open/,
        /\bopen\s*\(/  # Kernel#open
      ],
      database_writes: [
        /\.save[!\s(]/,
        /\.save$/,
        /\.update[!\s(]/,
        /\.update$/,
        /\.update_all/,
        /\.update_attribute/,
        /\.update_column/,
        /\.destroy[!\s(]/,
        /\.destroy$/,
        /\.destroy_all/,
        /\.delete[!\s(]/,
        /\.delete$/,
        /\.delete_all/,
        /\.create[!\s(]/,
        /\.create$/,
        /\.insert/,
        /\.upsert/,
        /ActiveRecord::Base\.connection\.execute/,
        /\.connection\.execute/
      ],
      dangerous_evals: [
        /\beval\s*\(/,
        /instance_eval/,
        /class_eval/,
        /module_eval/,
        /define_method/,
        /send\s*\(/,
        /__send__/,
        /public_send/,
        /method\s*\(/,
        /const_get/,
        /const_set/,
        /remove_const/,
        /class_variable_set/,
        /instance_variable_set/
      ],
      thread_operations: [
        /Thread\.new/,
        /Thread\.start/,
        /Thread\.fork/
      ]
    }.freeze
    
    # Validates the given code for security issues
    # @param code [String] The Ruby code to validate
    # @return [Hash] Validation result with :valid and :errors keys
    def self.validate(code)
      return { valid: false, errors: ['Code cannot be empty'] } if code.nil? || code.strip.empty?
      
      errors = []
      
      FORBIDDEN_PATTERNS.each do |category, patterns|
        patterns.each do |pattern|
          if code.match?(pattern)
            errors << format_error(category, pattern, code)
          end
        end
      end
      
      {
        valid: errors.empty?,
        errors: errors
      }
    end
    
    private
    
    # Formats an error message for a forbidden pattern match
    def self.format_error(category, pattern, code)
      matched_text = code.match(pattern)&.to_s || 'unknown'
      category_name = category.to_s.tr('_', ' ').capitalize
      
      "#{category_name} detected: '#{matched_text}' is not allowed for security reasons"
    end
  end
end
