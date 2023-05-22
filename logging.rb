require 'logger'
LOG = Logger.new(STDOUT)
LOG.formatter = proc { |severity, datetime, progname, msg|
  "#{severity}, #{datetime}, #{msg}\n"
}
