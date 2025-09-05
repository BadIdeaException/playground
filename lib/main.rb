#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require_relative 'cli'

Bundler.setup

CLI.start(ARGV)
