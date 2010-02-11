#!/usr/bin/env ruby

require 'readline'
require 'ui'

class CommandLineUI < UI
  
  def initialize(config)
    super
    @conference_mode = true
  end

  def run
    Readline.completion_proc = proc do |partial|
      if @current and @current.nick_list
        @current.nick_list.sort.find_all { |nick|
          re = "^(\\[.*?\\])?" + Regexp.quote(partial)
          nick.match re
        }
      else []
      end
    end

    loop do
      handle_line(Readline.readline('scout> ', true))
    end
  end

  def handle_line(line)
    case line
    when /^\/connect (.*?) (.*?)$/i
      connect $1, $2.to_i

    when /^\/disconnect (.*?)$/i
      @hubs.keys.each do |host|
        if host =~ (Regexp.new $1)
          @hubs[host].quit
          @hubs.delete host
        end
      end

    when /^\/favorites$/i
      favorites.each do |fav|
        puts fav
      end

    when /^\/favorite (.*?)$/i
      connect_to_favorite $1

    when /^\/regen/i
      @hubs.values.each do |hub|
        hub.regenerate_file_list
      end

    when /^\/for-each-hub (.*?)$/i
      @hubs.values.each do |it|
        eval $1
      end

    when /^\/chat-mode$/i
      $chat_mode = !$chat_mode

    when /^\/browse (.*?)$/i
      download_file $1, "MyList.DcLst"

    when /^\/get (.*?) (.*)$/i
      download_file $1, $2
      
    when /^\/search (.*)$/i
      search $1

    when /^test$/i
      download_file "[BBB]duud", "maxi\\movies\\Lost_Highway.avi"

    when /^save$/i
      save_config @config

    when /^([^\/].*)$/
      if @current
        @current.say $1
      else
        warning "You're not connected!\n"
      end
    end
  end

  def handle_hub_event(hub, type, data)
    case type
    when :got_hub_name
      info "Got hub name: %s\n", data[:name]

    when :chat
      chat "<%s> %s\n", data[:from], data[:text]

    when :privmsg
      chat "[%s] %s\n", data[:from], data[:text]

    when :mystery
      nil
#      warning "Mystery command: %s\n", data[:text]

    when :login_done
      interesting "Login done!\n"

    when :info
      unless @conference_mode
        info("%s <%s> on a %s sharing %s logged in.\n", 
             data[:nick], data[:email],
             data[:speed], data[:sharesize])
      end

    when :generating_file_list
      info "Generating file list... "

    when :done_generating_file_list
      interesting "done!\n"

    when :peer_connection
      interesting("Connected to peer %s on %d!\n",
                  data[:ip], data[:port])
      data[:connection].subscribe { |type, *args|
        handle_peer_event(data[:connection], type, *args)
      }

    when :got_nick_list
      interesting "Logged in users: "
      hub.nick_list.sort.each do |nick|
        info "%s ", nick
      end
      puts

    when :got_op_list
      interesting "Logged in ops: "
      hub.op_list.sort.each do |nick|
        info "%s ", nick
      end
      puts

    when :someone_logged_in
      unless @conference_mode
        info("Someone logged in\n")
      end

    else
      warning("Unhandled hub event %s: %s\n", type, data.inspect)
    end
  end

  def handle_search_event(info)
    info("%s (%d/%d) has `%s' (%d bytes).\n",
         info[:nick], info[:openslots], info[:totalslots],
         info[:path], info[:size])
  end

  def handle_peer_event(peer, type, data)
    case type
    when :nick
      info "%s's nickname is %s.\n", peer.hostname, data[:nick]
    when :direction
      info "%s wants to %s.\n", peer.remote_nick, data[:direction]
    when :get
      interesting("%s wants to download %s, starting at byte %d.\n",
                  peer.remote_nick, data[:path], data[:offset])
    when :send_request
      info("%s says `Send!'.  I shall obey, lest the Vile Moderators ban me!\n",
           peer.remote_nick)
    when :wrote
      info("Sent %d bytes to %s (%f%%).\n", data[:count],
           peer.remote_nick, data[:percent])
    when :write_error
      interesting "%s cancelled or something.\n", peer.remote_nick
      peer.kill_uploader
    when :disconnected
      interesting "Disconnected from %s.\n", peer.remote_nick
    when :downloaded_chunk
      info("%s from %s is %f%% (%d/%d) complete.\n",
           data[:file], data[:from], 100*data[:done].to_f/data[:size],
           data[:done], data[:size])
    when :done_downloading
      interesting("%s from %s is done!\n",
                  data[:file], data[:from])
    else
      warning("Unhandled peer event %s: %s\n", type, data.inspect)
    end
  end
end
