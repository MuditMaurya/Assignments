# Assignments
[![Build Status](https://travis-ci.org/MuditMaurya/Assignments.svg?branch=master)](https://travis-ci.org/MuditMaurya/Assignments)
[![HitCount](http://hits.dwyl.io/muditmaurya/Assignment.svg)](http://hits.dwyl.io/muditmaurya/Assignment)

## Blog
Small command-line blogging application which uses Sqlite3 for datebase. It performs the operation of adding,updating,listing and removing a post and adding,listing and removing a Category.


### Usage

```bash
bash blog.sh [OPTIONS]...
```
### Examples

This will print Help.

```bash
bash blog.sh --help[-h]
```

Below command will add a new blog post with the title and content given.

```bash
bash blog.sh post add "title" "content"
```

This will List all the Blog Posts.

```bash
bash blog.sh post list
```

This command will list all the blog posts where Keyword is found in title/content.

```bash
bash blog.sh post search "keywords"
```

This command will add a New Category if not already present.

```bash
bash blog.sh category add "category-name"
```

This Will list all the categories.

```bash
bash blog.sh category list
```

Below command will first check for the posts and categories existance if returned true will assign category to the post given by <post_id> and <category_id>.

```bash
bash blog.sh category assign <post_id> <cat_id>
```

This will first check if the category is present or not if present will add the post and assign the category and if not present will add the post and category.

```bash
bash blog.sh post add 'title' 'content' --category 'cat_name'
```

This will first check if the post is present, if true will delete the post.

```bash
bash blog.sh remove post <post_id>
```

Below command will first check if there is such category with this id, if yes then will check if the category is assigned to some post if no , will delete the category.

```bash
bash blog.sh remove category <cat_id>
```
