module DhEasy
  module Config
    # Manage configuration from a file.
    class Local
      # Configuration loaded from local configuarion file (see #load).
      #
      # @return [Hash,nil] `nil` when nothing has been loaded.
      attr_reader :local

      # Clear cache.
      def self.clear_cache
        @@local = {}
      end

      # Load into or from cache a configuration file contents.
      #
      # @param [String] file_path Configuration file path.
      # @param [Hash] opts ({}) Configuration options.
      # @option opts [Boolean] :force (false) Will reload configuration file
      #   when `true`.
      #
      # @return [Hash] Configuration file contents.
      def self.load_file file_path, opts = {}
        opts = {
          force: false
        }.merge opts

        return {} if file_path.nil?

        @@local ||= {}
        key = file_path = File.expand_path file_path
        return @@local[key] if !opts[:force] && @@local.has_key?(key)

        @@local[key] = (YAML.load_file(file_path) rescue {}) || {}
        @@local[key].freeze
      end

      # Default configuration file path list to be prioritized from first to last.
      #
      # @return [Array<String>] Configuration file path list. Default is
      #   `['./dh_easy.yaml', './dh_easy.yml']`
      def self.default_file_path_list
        @@default_file_path_list ||= [
          './dh_easy.yaml',
          './dh_easy.yml'
        ]
      end

      # Convert to hash.
      #
      # @return [Hash]
      def to_h
        local
      end

      # Get configuration key contents.
      #
      # @param [String] key Configuration option key.
      #
      # @return [Object,nil]
      def [](key)
        local[key]
      end

      # Lookup #file_path_list for the first valid file.
      #
      # @return [String,nil] Valid file path or `nil`.
      def lookup_file_path
        file_path_list.each do |candidate_file_path|
          next unless File.file?(File.expand_path(candidate_file_path))
          return candidate_file_path
        end
        nil
      end

      # Local configuration file path. It will lookup for the first valid file
      #   at #file_path_list as default value.
      #
      # @return [String] Configuration local file path.
      def file_path
        @file_path ||= lookup_file_path
      end

      # Local configuration file path list. It will prioritize from first to last.
      #
      # @return [Array<String>] Configuration local file path.
      def file_path_list
        @file_path_list ||= self.class.default_file_path_list
      end

      # Loads a local configuration file.
      #
      # @param [Hash] opts ({}) Configuration options.
      # @option opts [String] :file_path (nil) Configuration file path to load (see
      #   #file_path for configuration default file.)
      # @option opts [Boolean] :force (false) Will reload configuration file
      #   when `true`.
      def load opts = {}
        opts = {
          file_path: nil,
          force: false
        }.merge opts
        @file_path = opts[:file_path] || file_path
        @local = self.class.load_file(file_path, opts)
      end

      # Reloads local configuration file.
      def reload!
        load force: true
      end

      # Reset instance to lookup for valid files from #file_path_list and load
      #   the first valid configuration file found.
      def reset!
        @file_path = nil
        load force: true
      end

      # Initialize.
      #
      # @param [Hash] opts ({}) Configuration options (see #load).
      def initialize opts = {}
        @file_path_list = (opts.delete(:file_path_list) + []) unless opts[:file_path_list].nil?
        load opts
      end
    end
  end
end
