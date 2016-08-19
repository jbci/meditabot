require 'telegram_bot'
require 'sqlite3'
require 'rubygems'
require 'data_mapper'

#db = SQLite3::Database.new "test.db"
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite:///home/j/development/meditation_bot/test.db')

class Message
  include DataMapper::Resource

  property :id,         Serial
  property :from,       String
  property :text,       String
  property :reply_to_message,       String

  belongs_to :user
  belongs_to :channel
end

class User
  include DataMapper::Resource

  property :id,         Serial

  property :username,       String
  property :first_name,       String
  property :last_name,       String

  has n, :messages
end

class Channel
  include DataMapper::Resource

  property :id,         Serial
  property :username,       String
  property :title,       String
  property :date,       DateTime

  has n, :messages
end


DataMapper.finalize

DataMapper.auto_upgrade!

# @post = Post.create(
#   :title      => "My first DataMapper post",
#   :body       => "A lot of text ...",
#   :created_at => Time.now
# )


bot = TelegramBot.new(token: '269839176:AAFGN4CjYZqocXxvxi8io5kekJNQ0oFeTKI')
bot.get_updates(fail_silently: true) do |message|
  @user = User.first_or_create(
    :first_name => message.from.first_name,
    :last_name => message.from.last_name,
    :username => message.from.username
  )

  @channel = Channel.first_or_create(
    :username => message.from.username,
    :title => message.chat.title
  )

  @message = Message.new(
    :from => message.from.username,
    :text => message.text,
    :reply_to_message => message.reply_to_message
  )
  @message.user = @user
  @message.channel = @channel
  @message.save

  puts "@#{message.from.username}: #{message.text}"
  command = message.get_command_for(bot)
  puts command
  puts command.inspect
  message.reply do |reply|
    case command
    when /start/i
      reply.text = "Hello, #{message.from.first_name}! This Bot is under development, thanks for your patience."
    when /want/i
      reply.text = "Hello, #{message.from.first_name}! This Bot will warn you once every hour to meditate one minute."
    when /donotwant/i
      reply.text = "Hello, #{message.from.first_name}! This Bot will not warn you anymore unless you subscribe with the \"/want\" command."
    else
      reply.text = "#{message.from.first_name}, have no idea what #{command.inspect} means."
    end
    puts "sending #{reply.text.inspect} to @#{message.from.username}"
    reply.send_with(bot)
  end
end
