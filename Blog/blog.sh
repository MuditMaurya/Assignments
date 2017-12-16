#!/bin/bash
#SELECT * FROM post INNER JOIN category ON post.id=category.cat_id;
dpkg -s sqlite3 &> /dev/null
if [ $? -eq 0 ];
then
    echo "Package SQLite3 is Installed"
else
    echo -e "Package SQLite3 is not Installed \n"
    #Uncomment when not automated
    #echo "Do you want to Install the Package (y/n)"
    #read choice
    if [[$UID -ne 0]];
    then
        echo "You are not root user to Install, Run this script from root user to install"
        exit 0
    else
        if [$choice == "y"]
        then
            if apt-get install sqlite3 -y | tee -a install_log.log ;
            then
                echo "Successfully installed sqlite3"
            else
                echo "Error installing sqlite3"
                exit 0
            fi
        fi
    fi
fi
#Creating Database named "blog"
dbname="blog.db"
if [ ! -f $dbname ]
then
    cat /dev/null > blog.db
else
    echo "DB present"
fi
#Creating structure of the Table "blog" if not Exists then Create.
blog_table="CREATE TABLE IF NOT EXISTS post (id INTEGER PRIMARY KEY AUTOINCREMENT , cat_id INTEGER, title TEXT , content TEXT);"
echo $blog_table > /tmp/tmpblog_table
#Creating Structure of table Table "category" if not exist then Create.
category_table="CREATE TABLE IF NOT EXISTS category (cat_id INTEGER PRIMARY KEY AUTOINCREMENT , name TEXT );"
echo $category_table > /tmp/tmpcategory_table
sqlite3 $dbname < /tmp/tmpblog_table
sqlite3 $dbname < /tmp/tmpcategory_table
add_flag=
post_flag=
list_flag=
search_flag=
category_flag=
help(){
    echo "Help"
}
post_function(){
    echo "Post Function"
}
category_function(){
    echo "Category Function"
}
case $1 in
-h|--help)
    echo "HELP !!!"
    help
    ;;
post)
    post_flag=1
    case $2 in
    add)
        if [[ ! -z $5 ]] && [ ! -z $6 ]
        then
            case $5 in
                --category)
                    #category along with addition of the post
                    ;;
                * | "")
                    echo -e "Unknown option $5 / Empty Option \nTry --help | -h for more Information"
                    exit 0
                    ;;
            esac
        else
            #Inserting Into Table blog(DB)>post(structure)
            echo "Adding POST"
            if sqlite3 $dbname "INSERT INTO post(title , content) VALUES( '$3' , '$4')";
            then
                echo "Successfully added the post"
            else
                echo "Something went wrong ! "
                exit 0
            fi
        fi
        ;;
    list)
        echo "Listng all the Posts"
        #making query to list all the posts
        LIST=`sqlite3 $dbname 'SELECT id,title,content FROM post'`;
        #for each of the posts
        echo -e "Post ID --> Title --> Content \n"
        for posts in $LIST;
        do
            #Since sqlite3 returns a pipe seperated string
            post_id=`echo $posts | awk '{split($0,post,"|"); print post[1]}'`
            post_title=`echo $posts | awk '{split($0,post,"|");print post[2]}'`
            post_content=`echo $posts | awk '{split($0,post,"|");print post[3]}'`
            #Printing the posts and Contents
            echo -e $post_id "-->" $post_title"-->"$post_content"\n"; 
        done
        ;;
    search)
        echo "Searching for Keyword $3"
        search_query= 'SELECT * FROM post WHERE content LIKE %'$3'% OR title LIKE %'$3'%';
        Search=`sqlite3 $dbname`;
        ;;
    * | "")
        echo "Unknown Option: $2 / empty option  \nTry --help | -h for more information"
        exit 0
    esac
    #post_function $2 $3 $4
    ;;
category)
    category_flag=1
    case $2 in
    add)
        echo "Add category : $3"
        if sqlite3 $dbname "INSERT INTO category (name) VALUES ('$3');"
        then
            echo "Successfully Added the Category"
        else
            echo "Something Went Wrong !"
            exit 0
        fi
        ;;
    # Calling Category -> List
    list)
        echo "List Categories"
        #making query to list all the Categories along with their ID
        CAT_LIST=`sqlite3 $dbname 'SELECT cat_id,name FROM category'`;
        #for each of the Categories
        echo -e "Category ID-->Name \n"
        for cats in $CAT_LIST;
        do
            #Since sqlite3 returns a pipe seperated string
            cat_id=`echo $cats | awk '{split($0,cat,"|"); print cat[1]}'`
            cat_name=`echo $cats | awk '{split($0,cat,"|");print cat[2]}'`
            #Printing the posts and Contents
            echo -e $cat_id "-->" $cat_name"\n"; 
        done
        ;;
    assign)
        echo "Assigning $3 post to $4 category"
        if sqlite3 $dbname "UPDATE post SET cat_id ='$4' WHERE id='$3'";
        then
            echo "Assignment Task Successfully completed"
        else
            echo "Something Went Wrong !"
            exit 0
        fi
        ;;
    * | "")
        echo "Unknown Option: $1 / empty option  \nTry --help | -h for more information"
        exit 0
    esac
    #category_function $2 $3 $4
    ;;
* | "")
    echo -e "Unknown Option: $1 / empty option  \nTry --help | -h for more information"
    exit 0
    ;;
esac
#TO-DO
# post add title content --category cat_name
#if parameters are empty check
#Comments to be made properly
#make readme.md file
#check returned value from DB and print null in place of them
#search and list function not working properly need work there
#correct database hint:Reference
#cleaning
