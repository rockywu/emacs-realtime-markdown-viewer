#!/usr/bin/env ruby
# -*- coding:utf-8 -*-

require 'sinatra'
require 'sinatra-websocket'
require 'redcarpet'

set :server, 'thin'
set :sockets, []

get '/' do
  erb :index
end

get '/emacs' do
  request.websocket do |ws|
    ws.onopen { puts "@@ connect from emacs" }
    ws.onmessage do |msg|
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
                                         :autolink => true,
                                         :space_after_headers => true,
                                         :no_intra_emphasis => true,
                                         :tables => true,
                                         :fenced_code_blocks => true,
                                         :strikethrough => true,
                                         :lax_spacing => true,
                                         :space_after_headers => true,
                                         :superscript => true,
                                         :underline => true,
                                         :highlight => true,
                                         :quote => true,
                                         :footnotes => true)

      html = markdown.render(msg)
      EM.next_tick do
        settings.sockets.each{|s| s.send(html) }
      end
    end
    ws.onclose do
      settings.sockets.delete(ws)
    end
  end

end

get '/markdown' do
  request.websocket do |ws|
    ws.onopen do
      settings.sockets << ws
    end
    ws.onclose do
      warn("wetbsocket closed")
      settings.sockets.delete(ws)
    end
  end
end

get '/static/:file.min.:ext' do |file, ext|
  content_type ext
  send_file "static/#{file}.min.#{ext}"
end

__END__
@@ index
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Realtime Markdown Viewer</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script type="text/javascript" src="/static/jquery.min.js"></script>
  <link rel="stylesheet" href="/static/style.min.css">
</head>
<body>
  <div class="article">
  </div>
  <script type="text/javascript">
    $(function () {
      var ws = new WebSocket('ws://localhost:5021/markdown');
      ws.onopen = function () {
        console.log('connected');
      };
      ws.onclose = function (ev) {
        console.log('closed');
      };
      ws.onmessage = function (ev) {
        $('div.article').html(ev.data);
      };
      ws.onerror = function (ev) {
        console.log(ev);
      };
    });
  </script>
</body>
</html>
