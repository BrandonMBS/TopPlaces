//
//  FlickrTopPlacesHelper.m
//  TopPlaces
//
//  Created by Brandon Chatreau on 2014-06-12.
//  Copyright (c) 2014 Brandon Chatreau. All rights reserved.
//

#import "FlickrTopPlacesHelper.h"

@implementation FlickrTopPlacesHelper

+ (void)loadTopPlacesOnCompletion:(void (^)(NSArray *places, NSError *error))completionHandler
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[FlickrTopPlacesHelper URLforTopPlaces]
                                                completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                    NSArray *places;
                                                    if (!error) {
                                                        places = [[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:location]
                                                                                                  options:0
                                                                                                    error:&error] valueForKeyPath:FLICKR_RESULTS_PLACES];
                                                    }
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        completionHandler(places, error);
                                                    });
                                                }];
    [task resume];
}

+ (void)loadPhotosInPlace:(NSDictionary *)place
               maxResults:(NSUInteger)results
             onCompletion:(void (^)(NSArray *photos, NSError *error))completionHandler
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[FlickrTopPlacesHelper URLforPhotosInPlace:[place valueForKeyPath:FLICKR_PLACE_ID] maxResults:results]
                                                completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                    NSArray *photos;
                                                    if (!error) {
                                                        photos = [[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:location]
                                                                                                  options:0
                                                                                                    error:&error] valueForKeyPath:FLICKR_RESULTS_PHOTOS];
                                                    }
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        completionHandler(photos, error);
                                                    });
                                                }];
    [task resume];
}

+ (NSString *)titleOfPlace:(NSDictionary *)place
{
    return [[[place valueForKeyPath:FLICKR_PLACE_NAME]
             componentsSeparatedByString:@", "] firstObject];
}

+ (NSString *)subtitleOfPlace:(NSDictionary *)place
{
    NSArray *nameParts = [[place valueForKeyPath:FLICKR_PLACE_NAME]
                          componentsSeparatedByString:@", "];
    NSRange range;
    range.location = 1;
    range.length = [nameParts count] - 2;
    return [[nameParts subarrayWithRange:range] componentsJoinedByString:@", "];
}

+ (NSString *)countryOfPlace:(NSDictionary *)place
{
    return [[[place valueForKeyPath:FLICKR_PLACE_NAME]
             componentsSeparatedByString:@", "] lastObject];
}

+ (NSArray *)sortPlaces:(NSArray *)places
{
    return [places sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *name1 = [obj1 valueForKeyPath:FLICKR_PLACE_NAME];
        NSString *name2 = [obj2 valueForKeyPath:FLICKR_PLACE_NAME];
        return [name1 localizedCompare:name2];
    }];
}

+ (NSDictionary *)placesByCountries:(NSArray *)places
{
    NSMutableDictionary *placesByCountry = [NSMutableDictionary dictionary];
    for (NSDictionary *place in places) {
        NSString *country = [FlickrTopPlacesHelper countryOfPlace:place];
        NSMutableArray *placesOfCountry = placesByCountry[country];
        if (!placesOfCountry) {
            placesOfCountry = [NSMutableArray array];
            placesByCountry[country] = placesOfCountry;
        }
        [placesOfCountry addObject:place];
    }
    return placesByCountry;
}

+ (NSArray *)countriesFromPlacesByCountry:(NSDictionary *)placesByCountry
{
    NSArray *countries = [placesByCountry allKeys];
    countries = [countries sortedArrayUsingComparator:^(id a, id b) {
        return [a compare:b options:NSCaseInsensitiveSearch];
    }];
    return countries;
}

#define FLICKR_UNKNOWN_PHOTO_TITLE @"Unknown"

+ (NSString *)titleOfPhoto:(NSDictionary *)photo
{
    NSString *title = [photo valueForKeyPath:FLICKR_PHOTO_TITLE];
    if ([title length]) return title;
    
    title = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    if ([title length]) return title;
    
    return FLICKR_UNKNOWN_PHOTO_TITLE;
}

+ (NSString *)subtitleOfPhoto:(NSDictionary *)photo
{
    NSString *title = [FlickrTopPlacesHelper titleOfPhoto:photo];
    if ([title isEqualToString:FLICKR_UNKNOWN_PHOTO_TITLE]) return @"";
    
    NSString *subtitle = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    if ([title isEqualToString:subtitle]) return @"";
    
    return subtitle;
}

+ (NSString *)IDforPhoto:(NSDictionary *)photo
{
    return [photo valueForKeyPath:FLICKR_PHOTO_ID];
}

#define RECENT_PHOTOS_KEY @"Recent_Photos_Key"
+ (NSArray *)allPhtos
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:RECENT_PHOTOS_KEY];
}

#define RECENT_PHOTOS_MAX_NUMBER 20
+ (void)addPhoto:(NSDictionary *)photo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *photos = [[defaults objectForKey:RECENT_PHOTOS_KEY] mutableCopy];
    if (!photos) photos = [NSMutableArray array];
    NSUInteger key = [photos indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[FlickrTopPlacesHelper IDforPhoto:photo] isEqualToString:[FlickrTopPlacesHelper IDforPhoto:obj]];
    }];
    if (key != NSNotFound) [photos removeObjectAtIndex:key];
    [photos insertObject:photo atIndex:key];
    while ([photos count] > RECENT_PHOTOS_MAX_NUMBER){
        [photos removeLastObject];
    }
    [defaults setObject:photos forKey:RECENT_PHOTOS_KEY];
    [defaults synchronize];
}



@end
