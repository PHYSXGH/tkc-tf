# The TF config for the interstellar route planner

This TF config contains the infrastructure required to build and host the IRP application.

It includes a Cloud Run app and a BQ dataset and table, plus creates the required service accounts and enables the APIs as well.

The github workflow automatically deploys the resources from the main branch.

The only thing missing (and this may not even be possible in TF) is the trigger that starts the image building when the repo containing the Flask application is pushed to. This trigegr was set up manually and is not present here.
