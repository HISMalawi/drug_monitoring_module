module ReportHelper

  def stock_movement(params)

html =<<EOF
<html>
  <head>
<script type="text/javascript" src="/javascripts/jquery.js"></script>
<script type="text/javascript" src="/javascripts/Charts/Highcharts/highcharts.js"></script>
<script type="text/javascript" src="/javascripts/Charts/Highcharts/exporting.js"></script>

  </head>
  <body>
    <div id = 'graph'>
        display for graph
    </div>
  </body>
</html>
EOF
    html.html_safe
  end
end
