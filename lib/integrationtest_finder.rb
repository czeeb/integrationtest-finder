# The MIT License (MIT)
#
# Copyright (c) 2015 Chris Zeeb <chris.zeeb@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# Base class. Not very useful on its own.
class IntegrationtestFinder
  # Initializes the IntegrationtestFinder class
  def initialize
    @targets = []
  end

  # Adds targets
  #
  # @param [String] serverspec_dir
  def add_to_targets(serverspec_dir)
    Dir.glob(serverspec_dir).each do |dir|
      next unless File.directory?(dir)
      @targets.push(File.absolute_path(dir))
    end
  end

  # Returns list of targets
  #
  # @return [Array] List of directories that should contain integration tests
  def fetch_targets
    @targets.uniq
  end
end
