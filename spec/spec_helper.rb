require 'grid_in'
require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://postgres:@localhost/sat_grid_ins')

DB.run File.read('lib/grid_in.sql')
