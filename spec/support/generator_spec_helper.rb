require 'rails/generators/test_case'

# Custom matchers for generator tests
RSpec::Matchers.define :have_structure do |&block|
  match do |actual|
    @matcher = FileStructureMatcher.new(actual)
    @matcher.instance_eval(&block)
    @matcher.matches?
  end

  failure_message do |_|
    @matcher.failure_message
  end
end

# Matcher for 'contains' in file content
RSpec::Matchers.define :contain do |expected|
  match do |actual|
    actual.include?(expected)
  end

  failure_message do |actual|
    "expected #{actual} to contain #{expected}"
  end
end

class FileStructureMatcher
  attr_reader :root, :errors

  def initialize(root)
    @root = root
    @errors = []
    @checks = []
  end

  def directory(name, &block)
    @checks << DirectoryCheck.new(name, root, block)
  end

  def file(name, &block)
    @checks << FileCheck.new(name, root, block)
  end

  def matches?
    @errors = @checks.map(&:errors).flatten
    @errors.empty?
  end

  def failure_message
    errors.join("\n")
  end

  class Check
    attr_reader :name, :root, :block, :errors

    def initialize(name, root, block)
      @name = name
      @root = root
      @block = block
      @errors = []
    end

    def check_exists?
      path.exist?
    end

    def path
      Pathname.new(root).join(name)
    end

    def error(message)
      errors << message
    end
  end

  class DirectoryCheck < Check
    def initialize(name, root, block)
      super
      errors << "Directory #{path} does not exist" unless check_exists?
      instance_eval(&block) if check_exists? && block
    end

    def directory(name, &block)
      check = DirectoryCheck.new(name, path, block)
      errors.concat(check.errors)
    end

    def file(name, &block)
      check = FileCheck.new(name, path, block)
      errors.concat(check.errors)
    end
  end

  class FileCheck < Check
    def initialize(name, root, block)
      super
      errors << "File #{path} does not exist" unless check_exists?
      instance_eval(&block) if check_exists? && block
    end

    def contains(content)
      errors << "File #{path} does not contain '#{content}'" unless File.read(path).include?(content)
    end
  end
end

module GeneratorSpecHelpers
  def prepare_destination
    # Use a temporary directory
    dest = File.expand_path("../../../tmp", __FILE__)
    FileUtils.rm_rf(dest)
    FileUtils.mkdir_p(dest)
  end

  def run_generator(args = [])
    args += ["--quiet"] unless args.include?("--quiet")
    generator_class.start(args, destination_root: destination_root)
  end
end

RSpec.configure do |config|
  config.include GeneratorSpecHelpers, type: :generator
end