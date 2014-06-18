var ENVIRONMENT = "release";

var gulp = require('gulp');
var fs = require('fs');
var exec = require('child_process').execFile;
var path = require('path');
var merge = require('merge-stream');
var svg2png = require('gulp-svg2png');

var config = require('./buildconfig');
var environment = config.environment[ENVIRONMENT];

var host = '';

if (process.platform == 'win32') {
  host = 'winnt';
} else if (process.platform == 'linux') {
  host = 'linux';
} else {
  host = 'macos';
}

if (environment.transcc.config === '') {
  environment.transcc.args = environment.transcc.args.concat('-cfgfile=config.' + environment.transcc.config + '.' + host + '.txt');
}

if (config.path.transcc === '') {
  config.path.transcc = './bin';
}

var transcc = config.path.transcc + '/transcc_' + host;
var qmake = config.path.qt + '/qmake';

if (process.platform == 'win32') {
  transcc += '.exe';
  qmake += '.exe';
}

gulp.task('transcc', function(callback) {
  var src = './src/transcc';

  return exec(
    transcc,
    environment.transcc.args.concat(path.resolve(src, 'transcc.monkey')),

    function(err, stdout, stderr) {
      console.log(stdout);
      console.log(stderr);

      var origin = 'main_' + host;
      var dest = 'transcc_' + host;

      if (process.platform == 'win32') {
        origin += '.exe';
        dest += '.exe';
      }

      fs.renameSync(
        path.resolve(src, '.build/cpptool', origin),
        path.resolve('./bin', dest)
      );

      callback(err);
    }
  );
});

/*gulp.task('svg2png', function () {
 gulp.src('./src/resources/logo/*.svg')
 .pipe(svg2png())
 .pipe(gulp.dest('./.output/png'));
 });*/