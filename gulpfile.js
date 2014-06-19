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
var makedocs = bin + '/makedocs_' + host;

if (process.platform == 'win32') {
  transcc += '.exe';
  qmake += '.exe';
  make += '.exe';
  makedocs += '.exe';
}

var buildQtProject = function(projectName, projectDestName) {
  var src = './src/' + projectName;
  var buildDir = path.resolve(src, '.build');

  if (!projectDestName) {
    projectDestName = projectName;
  }

  return function(callback) {
    if (!fs.existsSync(buildDir)) {
      fs.mkdirSync(buildDir);
    } else {
      wrench.rmdirSyncRecursive(buildDir);
      fs.mkdirSync(buildDir);
    }

    exec(
      qmake,
      environment.qmake.args.concat(path.resolve(src, projectName + '.pro')),
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

              var origin = projectName;
              var dest = projectDestName;

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
  }
};

var buildMonkeyProject = function(projectName, projectDestName) {
  var src = './src/' + projectName;
  var buildDir = path.resolve(src, '.build');

  if (!projectDestName) {
    projectDestName = projectName;
  }

  return function(callback) {
    if (fs.existsSync(buildDir)) {
      wrench.rmdirSyncRecursive(buildDir);
    }

    return exec(
      transcc,
      environment.transcc.args.concat(["-builddir=.build", path.resolve(src, projectName + '.monkey')]),

      function(err, stdout, stderr) {
        console.log(stdout);
        console.log(stderr);

        var origin = 'main_' + host;
        var dest = projectDestName;

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
  }
};

gulp.task('dependencies', function(callback) {
  environment.qt.dependencies.forEach(function(item) {
    if (Array.isArray(item)) {
      item.forEach(function(dep) {
        fs.createReadStream(path.resolve(config.path.qt, dep)).pipe(fs.createWriteStream(path.resolve(bin, dep)));
      });
    } else {
      var dest = path.resolve(bin, path.basename(item));

      if (fs.existsSync(dest)) {
        wrench.rmdirSyncRecursive(dest);
      }

      wrench.copyDirRecursive(
        path.resolve(config.path.qt, item),
        dest,
        {forceDelete: false},
        callback
      );
    }
  });
});

gulp.task('docs', ['transcc', 'makedocs'],
  function(callback) {
    return exec(makedocs, function(err, stdout, stderr) {
      console.log(stdout);
      console.log(stderr);

      callback(err);
    });
  }
);

gulp.task('transcc', buildMonkeyProject('transcc', 'transcc_' + host));
gulp.task('makedocs', ['transcc'], buildMonkeyProject('makedocs', 'makedocs_' + host));
gulp.task('mserver', buildQtProject('mserver', 'mserver_' + host));
gulp.task('jentos', buildQtProject('jentos'));

gulp.task('default', ['dependencies', 'mserver', 'jentos', 'transcc', 'docs']);


/*gulp.task('svg2png', function () {
 gulp.src('./src/resources/logo/*.svg')
 .pipe(svg2png())
 .pipe(gulp.dest('./.output/png'));
 });*/