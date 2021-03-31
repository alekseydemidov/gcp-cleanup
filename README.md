**Description**  
gcr-clean.sh: Cleans up tagged or untagged images pushed before specified date
for a given repository (an image name without a tag/digest). But keep in repo LIMIT count of lates images.  

gcp-img-clean.sh: Cleans up VM instance images created before specified date and Family filter
for a given project. But keep in repo LIMIT count of latest images.

**Usage:**  
  gcr-clean.sh REPOSITORY DAYS LIMIT  
  
  REPOSITORY - required, GCR image adress  
  DAYS - optional, how old images should be removed. Default: 90  
  LIMIT - optional, how many images should be stay in repository regardless of date. Default: 0  


  gcp-img-clean.sh PROJECT 'FILTER' DAYS LIMIT  

  PROJECT - required, GCP project ID  
  FILTER - filter for image family which should be cleaned (quotas are required) e.g. 'my-app-image-(dev|prod)'  
  DAYS - optional, how old images should be removed. Default: 90  
  LIMIT - optional, how many images should be stay in project regardless of date. Default: 0  

**Example:**  
```gcr-clean.sh gcr.io/directory/my-app 120 40```  
Would clean up everything under the gcr.io/directory/my-app repository  
pushed before 120 days ago ( Default 90 days ), but keep last 40 images.  

```gcp-img-clean.sh my-gcp-project 'my-app-image-(dev|prod)' 120 40```  
Would clean up VM images under the my-gcp-project project  
created before 120 days ago ( Default 90 days ), but keep last 40 images.  
