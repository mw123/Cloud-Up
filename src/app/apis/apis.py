'''
Created on Jun 6, 2018

define blueprints here

@author: runshengsong
'''
from flask import Flask, render_template, flash, redirect
from flask import url_for, session, request, logging
from flask_mysqldb import MySQL
from wtforms import Form, StringField, TextAreaField, PasswordField, validators
from passlib.hash import sha256_crypt

from .mnist import blueprint as mnist_blueprint
from .InceptionV3 import blueprint as incept_blueprint
from .tasks import blueprint as tasks_blueprint

from app import app

app.secret_key='cloudup3031'

mysql = MySQL(app)

app.register_blueprint(mnist_blueprint, url_prefix = '/mnist')
app.register_blueprint(incept_blueprint, url_prefix = '/inceptionV3')
app.register_blueprint(tasks_blueprint, url_prefix='/tasks')

@app.route('/')
def index():
    return redirect(url_for('login'))

@app.route('/add')
def add_a():
    res = add.delay(3, 4)
  
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # Get form fields
        email = request.form['email']
        password_candidate = request.form['password']

        cur = mysql.connection.cursor()
        
        # Get user by email
        result = cur.execute("SELECT * FROM users WHERE email = %s", [email])

        if result > 0:
            # Get stored hash
            data = cur.fetchone()
            password = data['password']

            # Compare passwords
            if sha256_crypt.verify(password_candidate, password):
                app.logger.info('login success: {};{}'.format(email, data['username']))

                session['logged_in'] = True
                session['email'] = email
                session['username'] = data['username']
                session['aws_access_key_id'] = data['aws_access_key_id']
                session['aws_secret_access_key'] = data['aws_secret_access_key']

                flash('You are now logged in', 'success')
                return redirect(url_for('user_home'))
            else:
                app.logger.info('wrong password: {}'.format(email))
                
                error = 'Authentication failed'
                return render_template('login.html', error=error)
        else:
            error = 'Authentication failed'
            return render_template('login.html', error=error)

    return render_template('login.html')

class RegisterForm(Form):
    email = StringField('Email', [validators.Length(min=8, max=50)])
    username = StringField('Username', [validators.Length(min=4, max=25)])
    password = PasswordField('Password', [
        validators.DataRequired(),
    	validators.EqualTo('confirm', message='Passwords do not match')
    	])
    confirm = PasswordField('Confirm Password')
    aws_access_key_id = StringField('AWS Access Key ID', [validators.Length(min=10, max=100)])
    aws_secret_access_key = StringField('AWS Secret Access Key', [validators.Length(min=10, max=100)])

@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegisterForm(request.form)
    if request.method == 'POST' and form.validate():
        email = form.email.data
        username = form.username.data
        password = sha256_crypt.encrypt(str(form.password.data))
        aws_access_key_id = form.aws_access_key_id.data
        aws_secret_access_key = form.aws_secret_access_key.data

        app.logger.info('register info: {};{}'.format(email, username))
        
        # Create cursor
        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO users(email, username, password, aws_access_key_id, aws_secret_access_key) VALUES(%s,%s,%s,%s,%s)",
                    (email, username, password, aws_access_key_id, aws_secret_access_key))

        # Commit to DB
        mysql.connection.commit()

        cur.close()

        app.logger.info('register success')
        flash('You are now registered', 'success')

        return redirect(url_for('index'))
    return render_template('register.html', form=form)

@app.route('/dashboard')
def user_home():
    return render_template('dashboard.html')
