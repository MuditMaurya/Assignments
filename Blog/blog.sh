#!/bin/bash
#Checking if sqlite3 is installed
#Script for Travis-ci , Uncomment at various locations told for manual testing
if [[ ! -z "$7" ]]
then
    echo -e "To many Arguments.\nExiting."
    exit 0
fi
bold=$(tput bold)
normal=$(tput sgr0)
dpkg -s sqlite3 &> /dev/null
if [ "$?" -eq 0 ];
then
    echo "Package SQLite3 is Installed"
else
    echo -e "Package SQLite3 is not Installed \n"
    echo "Do you want to Install the Package (y/n)"
    read choice
    #Are you a root user
    if [ $UID -ne 0 ]
    then
        echo "You are not root user to Install, Run this script from root user to install"
        exit 0
    else
        if [[ "$choice" == "y" ]]
        then
            #installing sqlite3 if not installed
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
if [[ ! -f "$dbname" ]]
then
    echo "There is no DB"
    echo "Creating DB"
    cat /dev/null > blog.db
else
    echo "DB present"
fi
#Creating structure of the Table "blog" if not Exists then Create.
blog_table='CREATE TABLE IF NOT EXISTS post (post_id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT,content TEXT,cat_id INTEGER DEFAULT "Not_assigned_yet");'
echo $blog_table > /tmp/tmpblog_table
#Creating Structure of table Table "category" if not exist then Create.
category_table='CREATE TABLE IF NOT EXISTS category (cat_id INTEGER PRIMARY KEY AUTOINCREMENT,category TEXT , FOREIGN KEY(cat_id) REFERENCES post(post_id));'
echo $category_table > /tmp/tmpcategory_table
#Finally Creating table in database
sqlite3 $dbname < /tmp/tmpblog_table
sqlite3 $dbname < /tmp/tmpcategory_table
#Help function
help(){
    echo "${bold}Help${normal}"
    echo -e "Usage : bash blog.sh [OPTIONS].....\n"
    echo -e "${bold}Description${normal}\n"
    echo -e "Small command-line blogging application which uses Sqlite3 for datebase. It performs the operation of adding,updating,listing and removing a post and adding,listing and removing a Category.\n"
    echo -e "${bold}Arguments${normal}\n"
    echo -e "post\t\tFor adding/listing/searching a post in the blog.\ncategory\tFor adding/listing/assigning a category.\nremove\t\tFor Removing/Deleting a post/category from the blog.\n--help,-h\tFor Listing this help.\n"
    echo "${bold}Examples${normal}"
    echo -e "\nbash blog.sh --help[-h]\n\t Above will print this Help.\n"
    echo -e "bash blog.sh post add 'title' 'content'\n\t Above will add a new blog post with the title and content given.\n"
    echo -e "bash blog.sh post list\n\t Will List all the Blog Posts.\n"
    echo -e "bash blog.sh post search 'keywords'\n\t Will list all the blog posts where "Keyword" is found in title/content.\n"
    echo -e "bash blog.sh category add 'category-name'\n\t This command will add a New Category if not already present.\n"
    echo -e "bash blog.sh category list\n\t Will list all the categories.\n"
    echo -e "bash blog.sh category assign <post_id> <cat_id>\n\t Will first check for the posts and categories existance if returned true will assign category to the post given by <post_id> and <category_id>.\n"
    echo -e "bash blog.sh post add 'title' 'content' --category 'cat_name'\n\t This will first check if the category is present or not if present will add the post and assign the category and if not present will add the post and category.\n"
    echo -e "bash blog.sh remove post <post_id>\n\t This will first check if the post is present, if true will delete the post.\n"
    echo -e "bash blog.sh remove category <cat_id>\n\t Will first check if there is such category with this id, if yes then will check if the category is assigned to some post if no , will delete the category.\n"
}
#Checking what was the first argument
case $1 in
-h|--help)
    #calling Help function
    help
    ;;
#If first argument is "Post"
post)
    case $2 in
    #Whether adding/listing/searching a post
    add)
    #If categories is also passed during adding of post
    #Cheking id arguments are not empty
        if [[ ! -z "$5" ]] && [[ ! -z "$6" ]]
        then
            case $5 in
                --category)
                    #category along with addition of the post
                    #Checking if there is any category with same name
                    COUNT=`sqlite3 $dbname "SELECT cat_id FROM category WHERE category='$6';"`;
                    #Checking if Literally anything is returned which will mean that the category exists but also returns the id of the category
                    if [[ ! -z "$COUNT" ]]
                    then
                        echo "Category already exists"
                        #If category exists, add a new post and refer the category
                        if sqlite3 $dbname 'INSERT INTO post(title,content,cat_id) VALUES("'$3'","'$4'",$COUNT)';
                        then
                            echo "New post added and Assigned to the given category"
                        else
                            echo "Something went wrong !"
                        fi
                    else
                        #or else add a new category
                        echo "New Category Detected"
                        NEW=`sqlite3 $dbname "SELECT COUNT(cat_id) FROM category;"`;
                        NEW=`expr $NEW + 1`;
                        #adding a post along with the category
                        if sqlite3 $dbname 'INSERT INTO post(title,content,cat_id) VALUES("'$3'","'$4'",'$NEW')';
                        then
                            echo -e "Successfully added the Post\n"
                            #adding the category
                            if sqlite3 $dbname "INSERT INTO category(category) VALUES('$6')";
                            then
                                echo -e "Successfully added the Category\n"
                            else
                                echo "Something went wrong while adding Category";
                            fi
                        else
                            echo "Something Went Wrong while adding Post"
                        fi
                    fi
                    ;;
                    #if none of the arguments matched
                * | "")
                    echo -e "Unknown option $5 / Empty Option \nTry --help | -h for more Information"
                    exit 0
                    ;;
            esac
        else
            #Inserting Into Table blog(DB)>post(structure)
            echo "Adding POST"
            #Checking for empty arguments
            if [[ ! -z "$3" ]] && [[ ! -z "$4" ]]
            then
                #adding the post
                if sqlite3 $dbname "INSERT INTO post(title , content) VALUES( '${3}' , '${4}')";
                then
                    echo "Successfully added the post"
                else
                    echo "Something went wrong ! "
                    exit 0
                fi
            else
                echo -e "Arguments are empty \n Try --help | -h for more Information"
            fi
        fi
        ;;
    list)
        #blog.sh post list > will list all the posts in the DB
        list_check=`sqlite3 $dbname 'SELECT post_id FROM post WHERE cat_id!="Not_assigned_yet";'`;
        if [ ! -z "$list_check" ];
        then
            echo -e "- - - - - - - - - - - - - - - - -\n"
            echo -e "Listing all the Posts having assigned categories:\n"
            #making query to list all the posts with assigned categories
            LIST=`sqlite3 $dbname 'SELECT post_id,title,content,post.cat_id,category.category FROM post INNER JOIN category ON post.cat_id=category.cat_id;'`;
            #for each of the posts
            echo -e "Post ID --> Title --> Content --> Category ID --> Category \n"
            for posts in $LIST;
            do
                #Printing all the Assigned posts
                echo $posts 
            done
            echo -e "- - - - - - - - - - - - - - - - -\n"
        else
            echo -e "- - - - - - - - -\n"
            echo "Assigned Posts"
            echo "<----No Data to Show---->"
        fi
        list_check=`sqlite3 $dbname 'SELECT SUM(post_id) FROM post WHERE post.cat_id="Not_assigned_yet";'`;
        if [[ ! -z "$list_check" ]];
        then
            echo -e "- - - - - - - - - - - - - - - - -\n"
            echo -e "Listing post with Unassigned categories"
            #making query to list all the posts with unassigned category
            UNASSIGNED=`sqlite3 $dbname 'SELECT post_id,title,content,post.cat_id FROM post WHERE post.cat_id="Not_assigned_yet";'`;
            echo -e "\nPost ID --> Title --> Content --> Category ID \n"
            for uposts in $UNASSIGNED;
            do
                #Printing all the Unassigned posts
                echo $uposts;
            done
            echo -e "- - - - - - - - - - - - - - - - -\n"
        else
            echo -e "- - - - - - - - -\n"
            echo "Unassigned Posts"
            echo "<----No Data to Show---->"
        fi
        ;;
    search)
        #Search Operation
        #Checking if the argument is not empty
        if [[ ! -z "$3" ]]
        then
            #Search all the posts and 
            echo "Searching for Keyword : $3"
            search_query=`sqlite3 $dbname "SELECT post_id,title,content FROM post WHERE content LIKE '%$3%' OR title LIKE '%$3%';"`;
            if [[ ! -z "$search_query" ]]
            then
                for searches in $search_query;
                do
                    #Printing the Search Result
                    echo $searches;
                done
            else
                echo "No Result"
            fi
        else
            echo -e "Empty Arguments \n Try --help | -h for more information"
            exit 0
        fi
        ;;
    * | "")
        echo -e "Unknown Option: $2 / empty option  \nTry --help | -h for more information"
    esac
    ;;
category)
    # If performing operations on Category
    case $2 in
    add)
        #Adding a new category
        if [[ ! -z "$3" ]]
        then
            COUNT=`sqlite3 $dbname "SELECT cat_id FROM category WHERE category='$3';"`;
	        #Checking if Literally anything is returned which will mean that the category exists but also returns the id of the category
	        if [[ ! -z "$COUNT" ]]
            then
                echo "Category already exists"
            else
                #If its a new category not in database yet
                echo "Add category : $3"
                if sqlite3 $dbname "INSERT INTO category (category) VALUES ('$3');"
                then
                    echo "Successfully Added the Category"
                else
                    echo "Something Went Wrong !"
                    exit 0
                fi
            fi
        else
            echo -e "Empty Arguments \nTry --help | -h for more information"
        fi
        ;;
    list)
        #Will list all the categories
        echo "List Categories"
        #making query to list all the Categories along with their ID
        CAT_LIST=`sqlite3 $dbname 'SELECT cat_id,category FROM category'`;
        if [[ ! -z "$CAT_LIST" ]]
        then
            #for each of the Categories
            echo -e "Category ID-->Name \n"
            for cats in $CAT_LIST;
            do
                #Printing categories along with there IDs
                echo $cats
            done
        else
            echo "<----No Categories Yet---->"
        fi
        ;;
    assign)
        #Assigning operation post to its category
        #Checking for empty arguments
        if [[ ! -z "$3" ]] && [[ ! -z "$4" ]]
        then
            echo "Assigning $3 post to $4 category"
            #Checking if both of the arguments (Post ID and Category ID )does exist or not
            CHECK_POST_ID=`sqlite3 $dbname "SELECT post_id FROM post WHERE post_id='$3'"`;
            CHECK_CAT_ID=`sqlite3 $dbname "SELECT cat_id FROM category WHERE cat_id='$4'"`;
            if [[ ! -z "$CHECK_POST_ID" ]]
            then
                if [[ ! -z "$CHECK_CAT_ID" ]]
                then
                    #If exist then update them
                    if sqlite3 $dbname "UPDATE post SET cat_id=$4 WHERE post_id=$3;";
                    then
                        echo "Assignment Task Successfully completed"
                    else
                        echo "Something Went Wrong !"
                        exit 0
                    fi
                else
                    echo "Please Check Entered Category-ID";
                fi
            else
                echo "Please Check Entered Post-ID";
            fi
        else
            echo -e "Empty Arguments \nTry --help | -h for more information"
        fi
        ;;
    * | "")
        echo -e "Unknown Option: $1 / empty option  \nTry --help | -h for more information"
        exit 0
    esac
    ;;
remove)
    #Removing or Deleting a post/Category
    case $2 in
        #Deleting a post
        post)
            #Checking for empty argument
            if [[ ! -z "$3" ]]
            then
                #Checking if the requested to delete post exists or not
                CHECK_POST_ID=`sqlite3 $dbname "SELECT post_id FROM post WHERE post_id='$3'"`;
                if [[ ! -z "$CHECK_POST_ID" ]]
                then
                    #Printing all the Post to be deleted
                    PRINT=`sqlite3 $dbname "SELECT post_id,title,content,cat_id FROM post WHERE post_id='$3'"`;
                    echo -e "POST : "$PRINT"\n"
                    echo -e "Are you Sure you want to delete this post ? (y/n)"
                    read choice
                    if [[ "$choice" == 'y' ]]
                    then
                        #If user really wants to delete then Deleted
                        if `sqlite3 $dbname "DELETE FROM post WHERE post_id='$3'"`;
                        then
                            echo "Deleted Successfully";
                        else
                            echo "Something went Wrong !"
                        fi
                    else
                        echo "Wise Choice ;)";
                    fi
                else
                    echo "No such Post ID !"
                fi
            else
                echo "Post ID not mentioned";
                echo "Try --help | -h for more information"
            fi
            ;;
        category)
            #Deleting a Category
            #Checking for empty argument
            if [[ ! -z "$3" ]]
            then
                #Checking if requested category to be deleted exists or not
                CHECK_CAT_ID=`sqlite3 $dbname "SELECT cat_id FROM category WHERE cat_id='$3'"`;
                if [[ ! -z "$CHECK_CAT_ID" ]]
                then
                    #Cannot delete the Category if it is in use by some post
                    CHECK=`sqlite3 $dbname "SELECT SUM(cat_id) FROM post WHERE cat_id='$3'"`;
                    if [[ ! -z "$CHECK" ]]
                    then
                        echo -e "You cannot delete this category because some posts have this category \nMake sure this category is not in use by any posts"
                        exit 0
                    else
                        #Printing the category
                        PRINT=`sqlite3 $dbname "SELECT cat_id,category FROM category WHERE cat_id='$3'"`;
                        echo "Category : "$PRINT"\n"
                        echo -e "Are you Sure you want to delete this category ? (y/n)"
                        read choice
                        if [[ "$choice" == 'y' ]]
                        then
                            #If user really want to delete this category
                            if `sqlite3 $dbname "DELETE FROM category WHERE cat_id='$3'"`;
                            then
                                echo "Deleted Successfully";
                            else
                                echo "Something went Wrong !"
                            fi
                        else
                            echo "Wise Choice ;)";
                        fi
                    fi
                else
                    echo "No such Category ID !"
                fi
            else
                echo "Category ID not mentioned";
            fi
            ;;
        * | "")
            echo -e "Unknow option : '$2' /Empty Option \nTry --help | -h for more information"
            exit 0
            ;;
    esac
    ;;
    #Invalid option or Empty option
* | "")
    echo -e "Unknown Option: $1 / empty option  \nTry --help | -h for more information"
    exit 0
    ;;
esac
