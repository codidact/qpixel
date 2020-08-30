
/* database qpixel and user are already created *
   if you change your environment file, you need to update database names here */
CREATE DATABASE qpixel_dev;
CREATE DATABASE qpixel_test;
GRANT ALL ON qpixel_dev.* TO qpixel;
GRANT ALL ON qpixel_test.* TO qpixel;
GRANT ALL ON qpixel.* TO qpixel;
