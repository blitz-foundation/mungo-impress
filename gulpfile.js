var ENVIRONMENT = "release";

var gulp = require('gulp');
var fs = require('fs');
var exec = require('child_process').execFile;
var path = require('path');
var wrench = require('wrench');
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

if (environment.transcc.config !== '') {
  environment.transcc.args = environment.transcc.args.concat('-cfgfile=config.' + environment.transcc.config + '.' + host + '.txt');
}

if (config.path.transcc === '') {
  config.path.transcc = './bin';
}

var transcc = config.path.transcc + '/transcc_' + host;
var qmake = config.path.qt + '/qmake';
var make = config.path.mingw + '/mingw32-make';
var bin = './bin';

if (process.platform == 'win32') {
  transcc += '.exe';
  qmake += '.exe';
  make += '.exe';
}

gulp.task('transcc', function(callback) {
  var src = './src/transcc';
  var buildDir = path.resolve(src, '.build');

  if (fs.existsSync(buildDir)) {
    wrench.rmdirSyncRecursive(buildDir);
  }

  return exec(
    transcc,
    environment.transcc.args.concat(["-builddir=.build", path.resolve(src, 'transcc.monkey')]),

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
        path.resolve(bin, dest)
      );

      callback(err);
    }
  );
});

gulp.task('mserver', function(callback) {
  var src = './src/mserver';
  var buildDir = path.resolve(src, '.build');

  if (!fs.existsSync(buildDir)) {
    fs.mkdirSync(buildDir);
  } else {
    wrench.rmdirSyncRecursive(buildDir);
    fs.mkdirSync(buildDir);
  }

  exec(
    qmake,
    environment.qmake.args.concat(path.resolve(src, 'mserver.pro')),
    {
      cwd: buildDir
    },

    function(err, stdout, stderr) {
      console.log(stdout);
      console.log(stderr);

      if (!err) {
        exec(make, {cwd: buildDir},
          function(err, stdout, stderr) {
            console.log(stdout);
            console.log(stderr);

            var origin = 'mserver';
            var dest = 'mserver_' + host;

            if (process.platform == 'win32') {
              origin += '.exe';
              dest += '.exe';
            }

            var tmp = path.resolve(buildDir, 'release', origin);

            if (!fs.existsSync(tmp)) {
              tmp = path.resolve(buildDir, 'debug', origin);
            }

            fs.renameSync(
              tmp,
              path.resolve(bin, dest)
            );

            callback(err);
          }
        )
      } else {
        callback(err);
      }
    }
  );
});

gulp.task('dependencies', function(callback) {
  environment.qt.dependencies.forEach(function(item) {
    if (Array.isArray(item)) {
      item.forEach(function(dep) {
        fs.createReadStream(path.resolve(config.path.qt, dep)).pipe(fs.createWriteStream(path.resolve(bin, dep)));
      });
    } else {
      wrench.copyDirRecursive(
        path.resolve(config.path.qt, item),
        path.resolve(bin, path.basename(item)),
        {forceDelete: true},
        callback
      );
    }
  });
});

gulp.task('default', ['mserver', 'dependencies', 'transcc']);


/*gulp.task('svg2png', function () {
 gulp.src('./src/resources/logo/*.svg')
 .pipe(svg2png())
 .pipe(gulp.dest('./.output/png'));
 });*/