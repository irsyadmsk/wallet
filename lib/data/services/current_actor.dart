/// Who is using the app right now — set by `AuthController` on sign-in and
/// cleared on sign-out. Kept as a plain static holder so the data layer can
/// stamp authorship on new rows without depending on Supabase or GetX.
abstract class CurrentActor {
  static String? id;
  static String? name;

  static void set({required String? id, required String? name}) {
    CurrentActor.id = id;
    CurrentActor.name = name;
  }

  static void clear() => set(id: null, name: null);
}
