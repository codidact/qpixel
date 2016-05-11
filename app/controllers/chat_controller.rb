require 'securerandom'
require 'socket'

class IRCUser
  attr_accessor :has_authenticated, :just_changed, :is_op

  def initialize
    @has_authenticated = false
    @is_op = false
    $guest_counter += 1
  end
end

class ChatController < ApplicationController
  before_action :authenticate_user!
  @tokens = {}
  @guest_counter = 0
  
  Thread.new {
    socket = TCPSocket.new(get_setting("IRCHostname"), get_setting("IRCPort"))
    users = {}
    channels = []
    
    socket.puts("PASS #{get_setting("IRCPass")} TS 6 :#{get_setting("IRCServerID")}")
    socket.puts("CAPAB QS ENCAP SERVICES");
    socket.puts("SERVER #{get_setting("IRCServerName")} 1 #{get_setting("IRCServerID")} :#{get_setting("IRCPass")}")
    socket.puts("SVINFO 6 6 0 #{Time.now.to_i}")
    socket.puts(":#{get_setting("IRCServerID")} UID Community 1 #{Time.now.to_i} +o qpixel qpixel 0 #{get_setting("IRCServerID") + "AAAAAA"} :Robot")

    while message = socket.gets().split(" ")
      if message[0] == "PING"
        socket.puts("PONG :#{get_setting("IRCServerID")} #{message[1]}")
      elsif message[1] == "UID"
        message.pop() if(message[-1][0] = ":")
        users[message[-1]] = IRCUser.new()
        users[message[-1]].just_changed = true
        socket.puts(":#{get_setting("IRCServerID")} SVSNICK #{message[-1]} Guest#{@guest_counter} #{Time.now.to_i}")
        socket.puts(":#{get_setting("IRCServerID") + "AAAAAA"} PRIVMSG #{message[-1]} :You must authenticate before you can speak here. Log into QPixel and visit /chat to obtain a chat token, then type /msg Community <TOKEN>")
      elsif message[1] == "NICK"
        id = message[0][1..-1];
        if users[id].just_changed
          users[id].just_changed = false
        else
          socket.puts(":#{get_setting("IRCServerID")} KILL #{message[2]}")
          users.delete(id);
        end
      elsif message[1] == "QUIT"
        id = message[0][1..-1]
        users.delete(id)
      elsif message[1] == "SJOIN"
        channel = message[3];
        ids = message[5..-1].map { |id| id.gsub(/[^A-Z0-9]/, "") }
        if !channels.include?(channel)
          if !users[ids[0]].has_authenticated
            socket.puts(":#{get_setting("IRCServerID")} KICK #{channel} #{ids[0]} :Guests can't create channels.")
            for id in ids[1..-1]
              socket.puts(":#{get_setting("IRCServerID")} KICK #{channel} #{id} :Sorry about this.")
            end
          else
            socket.puts(":#{get_setting("IRCServerID") + "AAAAAA"} JOIN #{Time.new.to_i} #{channel} #{message[4]}")
            socket.puts(":#{get_setting("IRCServerID")} TMODE #{Time.new.to_i} #{channel} +m")
            socket.puts(":#{get_setting("IRCServerID")} TMODE #{Time.new.to_i} #{channel} +ov #{get_setting("IRCServerID") + "AAAAAA"}")
            channels.push(channel)
          end
        end

        for id in ids
          if users[id].has_authenticated
            socket.puts(":#{get_setting("IRCServerID")} TMODE #{Time.new.to_i} #{channel} +v #{id}")
          end
          if users[id].is_op
            socket.puts(":#{get_setting("IRCServerID")} TMODE #{Time.new.to_i} #{channel} +o #{id})")
          end
        end
      elsif message[1] == "JOIN"
        channel = message[3]
        id = message[0][1..-1]
        if !channels.include?(channel)
          if !users[id].has_authenticated
            socket.puts(":#{get_setting("IRCServerID")} KICK #{channel} #{id} :Guests can't create channels.")
          else
            socket.puts(":#{get_setting("IRCServerID") + "AAAAAA"} JOIN #{Time.new.to_i} #{channel} #{message[4]}")
            socket.puts(":#{get_setting("IRCServerID")} TMODE #{Time.new.to_i} #{channel} +m");
            socket.puts(":#{get_setting("IRCServerID")} TMODE #{Time.new.to_i} #{channel} +ov #{get_setting("IRCServerID") + "AAAAAA"}") 
            channels.push(channel);
          end
        end

        if users[id].has_authenticated
          socket.puts(":#{get_setting("IRCServerID")} TMODE #{Time.new.to_i} #{channel} +v #{id}")
        end
        if users[id].is_op
          socket.puts(":#{get_setting("IRCServerID")} TMODE #{Time.new.to_i} #{channel} +v #{id}")
        end
      elsif message[1] == "PRIVMSG"
        id = message[0][1..-1];
        login = message[-1][1..-1];
        if @tokens.key?(login)
          ident = @tokens[login]
          users[id].has_authenticated = true
          if ident.is_moderator || ident.is_admin
            users[id].is_op = true
          end
          socket.puts(":#{get_setting("IRCServerID")} SVSNICK #{message[-1]} #{ident.username} #{Time.now.to_i}")
          socket.puts(":#{get_setting("IRCServerID") + "AAAAAA"} PRIVMSG #{id} :Authenticated. Welcome!")
          @tokens.delete(login)
        else
          socket.puts(":#{get_setting("IRCServerID") + "AAAAAA"} PRIVMSG #{id} :Invalid token.")
        end
      end
    end
  }

  def index
  end

  def new_token
    id = SecureRandom.hex(8)
    @tokens[id] = current_user
    return id 
  end
end
