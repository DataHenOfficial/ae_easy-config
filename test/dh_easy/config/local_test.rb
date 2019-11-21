require 'test_helper'

describe 'local' do
  describe 'unit test' do
    it 'should load a YAML file' do
      data = DhEasy::Config::Local.load_file './test/input/config.yaml'
      expected = {
        'my_config' => {
          'sublevel' => {
            'collection' => [
              {'item_a' => 'A', 'aaa' => '111'},
              {'item_b' => 'B', 'bbb' => '222'},
              {'item_c' => 'C', 'ccc' => 333}
            ],
            'hash' => {
              'ddd' => 444,
              'eee' => 'EEE'
            }
          },
          'value_f' => 'fff'
        }
      }
      assert_equal expected, data
    end

    it 'should get root keys from index' do
      config = DhEasy::Config::Local.new file_path: './test/input/config.yaml'
      data = config['my_config']
      expected = {
        'sublevel' => {
          'collection' => [
            {'item_a' => 'A', 'aaa' => '111'},
            {'item_b' => 'B', 'bbb' => '222'},
            {'item_c' => 'C', 'ccc' => 333}
          ],
          'hash' => {
            'ddd' => 444,
            'eee' => 'EEE'
          }
        },
        'value_f' => 'fff'
      }
      assert_equal expected, data
    end

    it 'should use default file_path_list' do
      config = DhEasy::Config::Local.new
      assert_equal DhEasy::Config::Local.default_file_path_list, config.file_path_list
    end

    it 'should have default file path list as string collection' do
      list = DhEasy::Config::Local.default_file_path_list
      assert_instance_of Array, list
      assert_operator list.length, :>, 0
      list.each do |item|
        assert_instance_of String, item
      end
    end

    it 'should be able to modify default_file_path_list to keep compatiblity' do
      item = './test.yaml'
      list_orig = (DhEasy::Config::Local.default_file_path_list + [])
      list = (DhEasy::Config::Local.default_file_path_list + [])
      assert_equal list, DhEasy::Config::Local.default_file_path_list
      DhEasy::Config::Local.default_file_path_list << item
      refute_equal list, DhEasy::Config::Local.default_file_path_list
      list << item
      assert_equal list, DhEasy::Config::Local.default_file_path_list
      DhEasy::Config::Local.default_file_path_list.delete item
      assert_equal list_orig, DhEasy::Config::Local.default_file_path_list
    end

    describe 'with config file' do
      before do
        @temp_file = Tempfile.new(['config', '.yaml'], nil, encoding: 'UTF-8')
        @temp_file.puts "my_config:"
        @temp_file.puts "  hash:"
        @temp_file.puts "    ddd: 444"
        @temp_file.puts "    eee: EEE"
        @temp_file.puts "  value_f: 'fff'"
        @temp_file.flush
        @expected_orig = {
          'my_config' => {
            'hash' => {
              'ddd' => 444,
              'eee' => 'EEE'
            },
            'value_f' => 'fff'
          }
        }
        DhEasy::Config::Local.clear_cache
      end

      after do
        @temp_file.unlink
      end

      it 'should clear cache' do
        data_orig = DhEasy::Config::Local.load_file @temp_file.path
        assert_equal @expected_orig, data_orig
        @temp_file.puts 'ggg: 777'
        @temp_file.flush
        data_cached = DhEasy::Config::Local.load_file @temp_file.path
        assert_equal @expected_orig, data_cached
        DhEasy::Config::Local.clear_cache
        data_new = DhEasy::Config::Local.load_file @temp_file.path
        refute_equal @expected_orig, data_new
        expected = {'ggg' => 777}.merge @expected_orig
        assert_equal expected, data_new
      end

      it 'should save cache' do
        data_orig = DhEasy::Config::Local.load_file @temp_file.path
        assert_equal @expected_orig, data_orig
        @temp_file.puts 'ggg: 777'
        @temp_file.flush
        data_new = DhEasy::Config::Local.load_file @temp_file.path
        assert_equal @expected_orig, data_new
      end

      it 'should force load' do
        data_orig = DhEasy::Config::Local.load_file @temp_file.path
        assert_equal @expected_orig, data_orig
        @temp_file.puts 'ggg: 777'
        @temp_file.flush
        data_new = DhEasy::Config::Local.load_file @temp_file.path, force: true
        refute_equal @expected_orig, data_new
        expected = {'ggg' => 777}.merge @expected_orig
        assert_equal expected, data_new
      end

      it 'should force load' do
        config = DhEasy::Config::Local.new file_path: @temp_file.path
        data_orig = config.local
        assert_equal @expected_orig, data_orig
        @temp_file.puts 'ggg: 777'
        @temp_file.flush
        data_cached = config.local
        assert_equal @expected_orig, data_cached
        config.reload!
        data_new = config.local
        refute_equal @expected_orig, data_new
        expected = {'ggg' => 777}.merge @expected_orig
        assert_equal expected, data_new
      end

      it 'should convert to hash' do
        config = DhEasy::Config::Local.new file_path: @temp_file.path
        data = config.to_h
        assert_equal @expected_orig, data
      end
    end

    describe 'with several config file' do
      before do
        add_temp_file = lambda do |file_name|
          number = rand(111..999)
          string_upper = ('A'..'Z').to_a.shuffle[0, 3].join ''
          string_lower = ('a'..'z').to_a.shuffle[0, 3].join ''
          file = Tempfile.new([file_name, '.yaml'], nil, encoding: 'UTF-8')
          file.puts "my_config:"
          file.puts "  hash:"
          file.puts "    ddd: #{number}"
          file.puts "    eee: #{string_upper}"
          file.puts "  value_f: '#{string_lower}'"
          file.flush
          expected = {
            'my_config' => {
              'hash' => {
                'ddd' => number,
                'eee' => string_upper
              },
              'value_f' => string_lower
            }
          }
          return {
            file: file,
            expected: expected
          }
        end
        @temp_file_list = [
          add_temp_file.call('configA'),
          add_temp_file.call('configB'),
          add_temp_file.call('configC'),
          add_temp_file.call('configD'),
          add_temp_file.call('configE')
        ]
        DhEasy::Config::Local.clear_cache
      end

      after do
        @temp_file_list.each do |temp_file|
          temp_file[:file].unlink
        end
      end

      it 'should set file_path from file_path_list' do
        file_path_list = @temp_file_list.map{|v|v[:file].path}
        data_a = @temp_file_list[0]
        file_a = data_a[:file]
        config_a = DhEasy::Config::Local.new file_path_list: file_path_list
        assert_equal file_a.path, config_a.file_path
        assert_equal data_a[:expected], config_a.local

        file_path_list.shift
        data_b = @temp_file_list[1]
        file_b = data_b[:file]
        config_b = DhEasy::Config::Local.new file_path_list: file_path_list
        assert_equal file_b.path, config_b.file_path
        assert_equal data_b[:expected], config_b.local
      end

      it "should set file_path from file_path_list when priority files doesn't exists" do
        file_path_list = @temp_file_list.map{|v|v[:file].path}
        @temp_file_list.shift[:file].unlink
        @temp_file_list.shift[:file].unlink
        data = @temp_file_list[0]
        file = data[:file]
        config = DhEasy::Config::Local.new file_path_list: file_path_list
        assert_equal file.path, config.file_path
        assert_equal data[:expected], config.local
      end

      it 'should lookup a file_path from file_path_list' do
        file_path_list = @temp_file_list.map{|v|v[:file].path}
        @temp_file_list.shift[:file].unlink
        @temp_file_list.shift[:file].unlink
        @temp_file_list.shift[:file].unlink
        data = @temp_file_list[0]
        file = data[:file]
        config = DhEasy::Config::Local.new file_path_list: file_path_list
        assert_equal file.path, config.lookup_file_path
      end

      it "should return nil when lookup a file_path from file_path_list that doesn't exists" do
        file_path_list = @temp_file_list.map{|v|v[:file].path}
        @temp_file_list.each do |data|
          data[:file].unlink
        end
        @temp_file_list.clear
        config = DhEasy::Config::Local.new file_path_list: file_path_list
        assert_nil config.lookup_file_path
      end

      it 'should reset file_path from file_path_list' do
        file_path_list = @temp_file_list.map{|v|v[:file].path}
        data_a = @temp_file_list[0]
        file_a = data_a[:file]
        config = DhEasy::Config::Local.new file_path_list: file_path_list
        assert_equal file_a.path, config.file_path
        assert_equal data_a[:expected], config.local

        data_b = @temp_file_list[1]
        file_b = data_b[:file]
        config.file_path_list.shift
        config.reset!
        assert_equal file_b.path, config.file_path
        assert_equal data_b[:expected], config.local
      end
    end
  end
end
