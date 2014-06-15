var gulp = require('gulp');
var fs = require('fs');
var exec = require('child_process').execFile;
var path = require('path');
var merge = require('merge-stream');

var svg2png = require('gulp-svg2png');

var CFG_FILE = 'config.develop';
var HOST = '';

if (process.platform == 'win32') {
  HOST = 'winnt';
} else if (process.platform == 'linux') {
  HOST = 'linux';
} else {
  HOST = 'macos';
}

CFG_FILE += '.' + HOST + '.txt';
var TRANSCC = './bin/transcc_' + HOST;
var TRANSCC_DEF_ARGS = ['-config=release', '-target=C++_Tool', '-builddir=.build', '-cfgfile=' + CFG_FILE]

gulp.task('svg2png', function () {
  gulp.src('./src/resources/logo/*.svg')
    .pipe(svg2png())
    .pipe(gulp.dest('./.output/png'));
});

gulp.task('transcc', function(callback) {
  var src = './src/transcc';

  return exec(
    TRANSCC,
    TRANSCC_DEF_ARGS.concat(path.resolve(src, 'transcc.monkey')),
    function(err, stdout, stderr) {
      console.log(stdout);
      console.log(stderr);

      var origin = 'main_' + HOST;
      var dest = 'transcc_' + HOST;

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