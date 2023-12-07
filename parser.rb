#!/usr/bin/env ruby

require 'csv'
require 'active_record'
csv_path = 'ogb.csv'

# In-memory SQLite database for ActiveRecord
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

# Migrations to create tables
ActiveRecord::Schema.define do
  create_table :seminars do |t|
    t.string :date
  end

  create_table :books do |t|
    t.string :title
    t.string :isbn
    t.belongs_to :seminar, index: true
  end

  create_table :readings do |t|
    t.string :week
    t.string :pages
    t.belongs_to :book, index: true
  end
end

class Seminar < ActiveRecord::Base
  has_many :books
end

class Book < ActiveRecord::Base
  belongs_to :seminar
  has_many :readings
end

class Reading < ActiveRecord::Base
  belongs_to :book
end

CSV.foreach(csv_path, headers: true) do |row|
  next if row['Seminar'].nil?

  Seminar.find_or_create_by(date: row['Seminar'])
end

last_books = []
last_book = nil

CSV.foreach(csv_path, headers: true) do |row|
  if !row['Book'].nil?
    if Book.find_by(title: row['Book']).nil?
      last_book = Book.create(title: row['Book'], isbn: row['ISBN'])
    else
      last_book = Book.find_by(title: row['Book'])
      if !row['ISBN'].nil?
        last_book.isbn = row['ISBN']
        last_book.save
      end
    end
  end

  if !last_book.nil? && !row['Week'].nil? && !row['Pages'].nil?
    last_book.readings.create(week: row['Week'], pages: row['Pages'])
  end

  if row['Seminar'].nil? && !last_book.nil? && !last_books.include?(last_book)
    last_books << last_book
  end

  # Potentially more than one book to a seminar
  if last_books.any? && !row['Seminar'].nil?
    last_books.each do |book|
      book.seminar = Seminar.find_by(date: row['Seminar'])
      book.save
    end

    last_books = []
  end
end

CSV.open('seminars.csv', 'w') do |csv|
  csv << ['id', 'date']
  Seminar.all.each do |seminar|
    csv << [seminar.id, seminar.date]
  end
end

CSV.open('books.csv', 'w') do |csv|
  csv << ['id', 'title', 'isbn', 'seminar_id']  # Header row
  Book.all.each do |book|
    csv << [book.id, book.title, book.isbn, book.seminar_id]
  end
end

CSV.open('readings.csv', 'w') do |csv|
  csv << ['id', 'pages', 'week', 'book_id']
  Reading.all.each do |reading|
    csv << [reading.id, reading.pages, reading.week, reading.book_id]
  end
end
