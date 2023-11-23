#!/usr/bin/env ruby

require 'csv'

class Book
  @@next_id = 1
  @@books = []
  
  def self.all
    @@books
  end

  def self.find_or_create_by(title:, isbn:)
    book = @@books.find {|b| b.title == title }
    if book.nil?
      book = Book.new(title: title, isbn: isbn)
      @@books << book
    end
    book
  end

  attr_accessor :id, :title, :isbn
  
  def initialize(title:, isbn:)
    @id = @@next_id
    @@next_id += 1
    @title = title
    @isbn = isbn
  end
end

class Reading
  @@next_id = 1
  @@readings = []
  
  def self.all
    @@readings
  end

  def self.create(pages:, week:, book:)
    reading = Reading.new(pages: pages, week: week, book: book)
    @@readings << reading
    reading
  end

  attr_accessor :id, :pages, :week, :book
  
  def initialize(pages:, week:, book:)
    @id = @@next_id
    @@next_id += 1
    @pages = pages
    @week = week
    @book = book
  end
end

class Seminar 
  @@next_id = 1
  @@seminars = []

  def self.all
    @@seminars
  end

  def self.find_or_create_by(date:)
    seminar = @@seminars.find {|s| s.date == date} 
    if seminar.nil?
      seminar = Seminar.new(date: date)
      @@seminars << seminar
    end
    seminar
  end

  attr_accessor :id, :date

  def initialize(date:)
    @id = @@next_id
    @@next_id += 1
    @date = date 
  end
end

CSV.foreach('ogb.csv', headers: true) do |row|
  
  if !row['Book'].nil? && !row['ISBN'].nil?
    book = Book.find_or_create_by(title: row['Book'], isbn: row['ISBN'])
  end

  if !row['Pages'].nil? && !row['Week'].nil? && !book.nil?
    reading =Reading.create(
      pages: row['Pages'], 
      week: row['Week'],
      book: book
    )
  end

  if !row['Seminar'].nil? 
    date = Date.parse(row['Seminar'])
    seminar = Seminar.find_or_create_by(date: date)
    if !book.nil?
      book.seminar = seminar
    end
  end

  if !row['Seminar'].nil? && !reading.nil?
    date = Date.parse(row['Seminar'])
    seminar = Seminar.find_or_create_by(date: date)
    reading.seminar = seminar
  end

end

# Export normalized data
CSV.open('books.csv', 'w') do |csv|
  csv << ['id', 'title', 'isbn']
  Book.all.each do |book|
    csv << [book.id, book.title, book.isbn]
  end
end

# Export readings 
CSV.open('readings.csv', 'w') do |csv|
  csv << ['id', 'pages', 'week', 'book_id']
  Reading.all.each do |reading|
    csv << [reading.id, reading.pages, reading.week, reading.book.id]
  end  
end

# Export seminars
CSV.open('seminars.csv', 'w') do |csv|
  csv << ['id', 'date']
  Seminar.all.each do |seminar|
    csv << [seminar.id, seminar.date]
  end
end
